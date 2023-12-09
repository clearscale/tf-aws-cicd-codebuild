#
# Import standardization module
#
module "context" {
  source    = "../tf-context"
  providers = { aws = aws }

  prefix   = var.prefix
  client   = var.client
  project  = var.project
  accounts = [var.account]
  env      = var.env
  region   = var.region
  name     = var.name
  function = (var.project_name == null) ? var.repo.name : var.project_name
}

resource "aws_codebuild_project" "this" {
  name           = local.cb_project_name
  description    = var.description
  service_role   = aws_iam_role.this.arn
  encryption_key = var.encryption_key

  artifacts {
    type = "CODEPIPELINE"
  }

  dynamic "cache" {
    for_each = var.cache != null ? [var.cache] : []
    content {
      type     = cache.value.type
      modes    = cache.value.modes
      location = replace(cache.value.location, "arn:aws:s3:::", "")
    }
  }

  environment {
    compute_type                = var.compute.compute_type
    image                       = var.compute.image
    type                        = var.compute.type
    image_pull_credentials_type = (startswith(var.compute.image, "aws/codebuild/")
      ? "CODEBUILD"
      : "SERVICE_ROLE"
    )
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file(var.script)
  }

  vpc_config {
    vpc_id             = local.vpc_config.vpc_id
    subnets            = local.vpc_config.subnets
    security_group_ids = local.vpc_config.security_group_ids
  }

  lifecycle {
    ignore_changes = [
      tags, tags_all
    ]
  }
}