resource "aws_ecr_repository" "flask_cicd" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }

  image_tag_mutability_exclusion_filter {
    filter      = "dev-*"
    filter_type = "WILDCARD"
  }


  image_scanning_configuration {
    scan_on_push = true

  }

  encryption_configuration {
    encryption_type = "AES256"

  }

  tags = {
    Name        = "flask-cicd-repo"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

}