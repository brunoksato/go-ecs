# Golang ECS

 -This is a basic repository to create fast infrastucture ecs with golang integrate with CircleCI

* Follow steps

-Create a repository in ECS `aws ecr create-repository --repository-name go-ecs`
-Create a cluster in ECS, follow this doc <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create_cluster.html>
-Add ENVS in CircleCI
  *AWS_REGION='us-east-1'
  *DOCKER_NAME='go-ecs'
  *TASK_NAME='go-ecs-default'
  *TASK_FAMILY='go-ecs'
  *SERVICE_NAME='go-ecs-service'
  *CLUSTER_NAME='go-ecs-cluster'
-Push code to github and done