provider "aws" {
  region = "us-west-2"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-vpc"
  }
}

# Create Subnets
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ecs-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "ecs-subnet-b"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "ecs-igw"
  }
}

# Attach Internet Gateway to VPC
resource "aws_internet_gateway_attachment" "igw_attach" {
  vpc_id              = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

# Create Route Table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ecs-public-route-table"
  }
}

# Associate Subnets with Route Table
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_route.id
}

# Create Security Group
resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "ecs_security_group"
  description = "Allow HTTP inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-security-group"
  }
}

# Create Load Balancer
resource "aws_lb" "main" {
  name               = "ecs-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  tags = {
    Name = "ecs-load-balancer"
  }
}

# Create Target Group
resource "aws_lb_target_group" "my_target_group" {
  name        = "ecs-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  tags = {
    Name = "ecs-target-group"
  }

  health_check {
    path                = "/health_check"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    protocol            = "HTTP"
    port                = 5000
  }
}

# Create Listener for Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "5000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}


# Create ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "fargate-cluster"
}

# Reference Existing ECR Repository 
data "aws_ecr_repository" "existing_repo" {
  name = "my-ecr-repository"
}

resource "aws_ecr_repository" "my_repository" {
  count = data.aws_ecr_repository.existing_repo.id != "" ? 0 : 1

  name = "my-ecr-repository"
}


# Create IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach IAM Policy to ECS Task Role for CloudWatch Logs and ECR access
resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_role.name
}

# Create an S3 bucket
resource "aws_s3_bucket" "app_data" {
  bucket = "no-name-like-this"
  tags = {
    Name = "App Data Bucket"
  }
}

# Create an IAM policy for S3 access
resource "aws_iam_policy" "ecs_s3_access" {
  name = "ecs-s3-access"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.app_data.arn}",

        
        "${aws_s3_bucket.app_data.arn}/*"
      ]
    }
  ]
}
POLICY
}

# Attach the IAM policy to the ECS Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_s3_access.arn
  role       = aws_iam_role.ecs_task_role.name
}


# Create ECS Task Definition with new IAM Role
resource "aws_ecs_task_definition" "task" {
  family                   = "fargate-task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn  
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[{
  "name": "my-container",
  "image": "888577038689.dkr.ecr.us-west-2.amazonaws.com/my-ecr-repository",  
  "essential": true,
  "memory": 512,
  "cpu": 256,
  "portMappings": [{
    "containerPort": 5000,
    "hostPort": 5000
  }],
  "environment": [
    {
      "name": "S3_BUCKET_NAME",
      "value": "${aws_s3_bucket.app_data.bucket}"
    }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "/ecs/fargate-task",
      "awslogs-region": "us-west-2",
      "awslogs-stream-prefix": "ecs"
    }
  }
}]
DEFINITION
}

# CloudWatch Log Group for ECS Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/fargate-task"
}

# Create ECS Service
resource "aws_ecs_service" "fargate_service" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 5000
  }

  tags = {
    Name = "fargate-service"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.fargate_cluster.name}/${aws_ecs_service.fargate_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scaling Policy to Increase Tasks
resource "aws_appautoscaling_policy" "scale_up" {
  name               = "ecs-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    step_adjustment {
      scaling_adjustment = 1
      metric_interval_lower_bound = 0
    }
    cooldown = 60
  }
}

# Scaling Policy to Decrease Tasks
resource "aws_appautoscaling_policy" "scale_down" {
  name               = "ecs-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    step_adjustment {
      scaling_adjustment = -1
      metric_interval_upper_bound = 0
    }
    cooldown = 60
  }
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.fargate_cluster.name
    ServiceName = aws_ecs_service.fargate_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]
}

# CloudWatch Alarm for Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  alarm_name          = "ecs-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    ClusterName = aws_ecs_cluster.fargate_cluster.name
    ServiceName = aws_ecs_service.fargate_service.name
  }

  # Set to only trigger scale down if the desired count is above 2
  alarm_actions = [
    aws_appautoscaling_policy.scale_down.arn
  ]
  
  # Add a condition to prevent scaling below 2 tasks
  insufficient_data_actions = []
  ok_actions               = []
}




# Output ECS Service URL
output "ecs_service_url" {
  value = aws_lb.main.dns_name
}
