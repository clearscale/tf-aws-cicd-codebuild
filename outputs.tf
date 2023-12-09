output "name" {
  description = "The name of the CodeBuild project."
  value       = local.cb_project_name
}

output "id" {
  description = "Name (if imported via name) or ARN (if created via Terraform or imported via ARN) of the CodeBuild project."
  value       = aws_codebuild_project.this.id
}

output "arn" {
  description = "The ARN of the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}

output "role" {
  description = "Service role information."
  value = {
    id          = aws_iam_role.this.id
    arn         = aws_iam_role.this.arn
    name        = aws_iam_role.this.name
    unique_id   = aws_iam_role.this.unique_id
    create_date = aws_iam_role.this.create_date
  }
}

output "stage_roles" {
  description = "Role names of all the CodePipeline stages that were specified as var.stages."
  value       = local.iam_stage_roles
}

output "badge_url" {
  description = "The ARN of the CodeBuild project."
  value       = aws_codebuild_project.this.badge_url
}

output "public_project_alias" {
  description = " The project identifier used with the public build APIs.."
  value       = aws_codebuild_project.this.public_project_alias
}

output "tags_all" {
  description = "All tags applied to the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}