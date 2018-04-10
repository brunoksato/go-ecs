# Evaluate ECR LogIn Command From AWS
eval $(aws ecr get-login --no-include-email --region $AWS_REGION)

# Build the docker image
docker build --rm -f Dockerfile -t ${DOCKER_NAME} .

# Tag the docker image
docker tag ${DOCKER_NAME}:latest ${DOCKER_REPO}:${CIRCLE_BUILD_NUM}

# Deploy it to ECR
docker push ${DOCKER_REPO}:${CIRCLE_BUILD_NUM}
if [ $? != 0 ]; then
  echo "Build Failed"
  exit
fi

# Create a Task Definition
task_def='[{
  "name": "%s",
  "image": "%s:%s",
  "essential": true,
  "memoryReservation": 1000,
  "memory": 1000,
  "portMappings": [
    {
      "containerPort": 8080,
      "hostPort": 80
    }
  ]
}]'

task_def=$(printf "$task_def" $TASK_NAME $DOCKER_REPO $CIRCLE_BUILD_NUM)

# Register task definition
json=$(aws ecs register-task-definition --region $AWS_REGION --container-definitions "$task_def" --family ${TASK_FAMILY})
if [ $? != 0 ]; then
  echo "Deployment Failed"
  exit
fi

# Grab revision # using regular bash and grep
revision=$(echo "$json" | grep -o '"revision": [0-9]*' | grep -Eo '[0-9]+')

# Deploy revision
aws ecs update-service --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition "$TASK_NAME":"$revision"
if [ $? != 0 ]; then
  echo "Deployment Failed"
  exit
fi

# Wait until the service runs with the new task revision
SERVICE_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | head -1`
RUNNING_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | tail -1`
echo "SERVICE_TASK:" $SERVICE_TASK
echo "RUNNING_TASK:" $RUNNING_TASK
while [[ $SERVICE_TASK != $RUNNING_TASK ]]; do
    sleep 10
    SERVICE_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | head -1`
    RUNNING_TASK=`aws ecs describe-services --region $AWS_REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME | egrep "taskDefinition" | tr ":" " " | awk '{print $8}' | sed 's/",//' | tail -1`
    echo "Waiting for recent task running Service Task:"$SERVICE_TASK" Running Task:"$RUNNING_TASK
done

echo "Task $RUNNING_TASK has been deployed successfully"