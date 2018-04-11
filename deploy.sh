# Variables
AWS_ACCOUNT_ID='YOU_ACCOUNT_ID'
#AWS_REGION='us-east-2'
DOCKER_NAME='go-ecs'
TASK_NAME='go-ecs-task'
TASK_FAMILY='go-ecs-task'
SERVICE_NAME='go-ecs-service'
CLUSTER_NAME='go-ecs-cluster'
#CIRCLE_BUILD_NUM='1'

# Evaluate ECR LogIn Command From AWS
aws configure set region $AWS_REGION
echo $(aws ecr get-login --no-include-email)
# echo $(aws ecr get-authorization-token --region $AWS_REGION --output text --query 'authorizationData[].authorizationToken' | base64 -d | cut -d: -f2) | docker login -u AWS https://$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com --password-stdin

# Build the docker image
echo 'Build the docker image'
docker build --rm -f Dockerfile -t $DOCKER_NAME .

# Tag the docker image
echo 'Tag the docker image'
docker tag $DOCKER_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DOCKER_NAME:$CIRCLE_BUILD_NUM

# Deploy it to ECR
echo 'Deploy it to ECR'
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DOCKER_NAME:$CIRCLE_BUILD_NUM
if [ $? != 0 ]; then
  echo "Build Failed"
  exit
fi

# Create a Task Definition
echo 'Create a Task Definition'
task_template='[{
  "name": "%s",
  "image": "%s.dkr.ecr.%s.amazonaws.com/%s:%s",
  "essential": true,
  "memory": 256,
  "cpu": 10,
  "portMappings": [
    {
      "containerPort": 8080,
      "hostPort": 80
    }
  ]
}]'

task_def=$(printf "$task_template" $TASK_NAME $AWS_ACCOUNT_ID $AWS_REGION $DOCKER_NAME $CIRCLE_BUILD_NUM)

# Register task definition
echo 'Register task definition'
json=$(aws ecs register-task-definition --region $AWS_REGION --container-definitions "$task_def" --family $TASK_FAMILY)
if [ $? != 0 ]; then
  echo "Deployment Failed"
  exit
fi

# Grab revision # using regular bash and grep
echo 'Grab revision'
revision=$(echo "$json" | grep -o '"revision": [0-9]*' | grep -Eo '[0-9]+')

# Deploy revision
echo 'Deploy revision'
aws ecs update-service --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition "$TASK_NAME":"$revision"
if [ $? != 0 ]; then
  echo "Deployment Failed"
  exit
fi

# Wait until the service runs with the new task revision
echo 'Wait until the service runs with the new task revision'
SERVICE_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | head -1`
RUNNING_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --profile petmondo | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | tail -1`
echo "SERVICE_TASK:" $SERVICE_TASK
echo "RUNNING_TASK:" $RUNNING_TASK
while [[ $SERVICE_TASK != $RUNNING_TASK ]]; do
    sleep 10
    SERVICE_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --profile petmondo | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | head -1`
    RUNNING_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --profile petmondo | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | tail -1`
    echo "Waiting for recent task running Service Task:"$SERVICE_TASK" Running Task:"$RUNNING_TASK
done

echo "Task $RUNNING_TASK has been deployed successfully"
