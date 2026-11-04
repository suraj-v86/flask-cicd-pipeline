output "ecr_repository_name" {
  description = "Name of the ecr repository"
  value       = aws_ecr_repository.flask_cicd.name
}

output "ecr_repository_url" {
  description = "URL of the ecr repository"
  value       = aws_ecr_repository.flask_cicd.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of ECR repository"
  value       = aws_ecr_repository.flask_cicd.arn
}