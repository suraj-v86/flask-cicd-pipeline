variable "aws_region" {
  description = "AWS region where ECR will be created"
  type        = string
  default     = "us-east-1"

}

variable "ecr_repository_name" {
  description = "Name of the ecr repository"
  type        = string
  default     = "flask-cicd-repo"

}