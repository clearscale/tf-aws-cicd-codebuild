locals {
  client       = lower(replace(var.client, " ", "-"))
  project      = lower(replace(var.project, " ", "-"))
  account_id   = lower(trimspace(replace(var.account.id,   "-", "")))
  account_name = lower(trimspace(replace(var.account.name, "-", "")))
  envname      = lower(trimspace(var.env))
  region       = lower(replace(replace(var.region, " ", "-"), "-", ""))
  name         = lower(replace(var.name, " ", "-"))

  cb_project_name = (lower(replace(replace(
    module.std.names.aws[var.account.name].general,
  "-", " "), " ", "-")))

  iam_service_role_policies = (var.iam_service_role_policies == null
    ? []
    : var.iam_service_role_policies
  )

  rex_arn = "arn:aws:([^:]+)?:([^:]+)?:([0-9]+)?:"
  account_codecommit = try(
    regex(local.rex_arn, var.repo.role_arn)[2], true
  )
  bucket_names = (upper(try(upper(var.cache.type), "!S3"))  == "S3"
    ? [element(split("/", replace(var.cache.location, "arn:aws:s3:::", "")), 0)]
    : []
  )

  # Set testing vpc config if var.vpc is not set
  vpc_config = {
    vpc_id = ((var.vpc == null || var.env == "sandbox")
      ? data.aws_vpc.this[0].id
      : var.vpc.id
    )
    subnets = ((var.vpc == null || var.env == "sandbox")
      ? [for subnet in data.aws_subnets.this : subnet.ids][0]
      : var.vpc.subnets
    )
    security_group_ids = ((var.vpc == null || var.env == "sandbox")
      ? [data.aws_security_group.this[0].id]
      : var.vpc.security_groups
    )
  }

  # Get IAM role names and ARNs using the standardization module output
  iam_role_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/"
  iam_role_raw    = module.std.names.aws[var.account.name].title
  iam_role        = (startswith(local.iam_role_raw, local.iam_role_prefix)
    ? local.iam_role_raw
    : "${local.iam_role_prefix}${local.iam_role_raw}"
  )

  # Set var.stages[x].action.configuration.ProjectName with var.stages[x].name if null or empty.
  # var.stages is only required if CodePipeline is being used with this Build Project.
  stages = (var.stages == null ? null : [for stage in var.stages : {
    name = stage.name
    action = {
      name            = stage.action.name
      category        = stage.action.category
      provider        = stage.action.provider
      version         = stage.action.version
      owner           = stage.action.owner
      region          = stage.action.region
      input_artifacts = stage.action.input_artifacts
      configuration   = {
        ProjectName = coalesce(stage.action.configuration.ProjectName, stage.name)
      }
      resource = stage.resource
      secrets  = stage.secrets
      logs     = stage.logs
    }
  }])
}

variable "prefix" {
  type        = string
  description = "(Optional). Prefix override for all generated naming conventions."
  default     = "cs"
}

variable "client" {
  type        = string
  description = "(Optional). Name of the client"
  default     = "ClearScale"
}

variable "project" {
  type        = string
  description = "(Optional). Name of the client project."
  default     = "pmod"
}

variable "account" {
  description = "(Optional). Cloud provider account object."
  type = object({
    key      = optional(string, "current")
    provider = optional(string, "aws")
    id       = optional(string, "*") 
    name     = string
    region   = optional(string, null)
  })
  default = {
    id   = "*"
    name = "shared"
  }
}

variable "env" {
  type        = string
  description = "(Optional). Name of the current environment."
  default     = "dev"
}

variable "region" {
  type        = string
  description = "(Optional). AWS region."
  default     = "us-west-1"
}

variable "name" {
  type        = string
  description = "(Optional). The name of the CodeBuild project. Used to add additional context to dependency resources like IAM roles. Project name should be added to var.project_name."
  default     = "codebuild"
}

variable "project_name" {
  type        = string
  description = "(Required). Unrelated to var.project and var.name. This represents the name of the CodeBuild Project."
  default     = null
}

variable "description" {
  description = "(Optional). Description of the CodeBuild project."
  type        = string
  default     = "A CodeBuild project brought to you by ClearScale."
}

#
# KMS key ARN
#
variable "encryption_key" {
  description = "(Optional). KMS key ARN."
  type        = string
  default     = null
}

#
# Additional IAM policy ARNs for the primary IAM service role.
# Example:
#   iam_assume_role_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
#
variable "iam_service_role_policies" {
  description = "(Optional). List of IAM policy ARNs to attach to the primary service role."
  type        = list(string)
  default     = []
}

#
# Cache store definition
#
variable "cache" {
  description = "(Optional). Cache store"
  type = object({
    type      = optional(string, "S3")
    location  = optional(string, null)
    modes     = optional(list(string), [])
  })
  default = null
}

#
# Compute environment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#environment
# https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
#
variable "compute" {
  description = "(Optional). Environment (Compute Resource) configuration for the CodeBuild project."
  type = object({
    compute_type = optional(string, "BUILD_GENERAL1_SMALL")
    image        = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
    type         = optional(string, "LINUX_CONTAINER")
  })
  default = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }
}

#
# Networking configuration
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#vpc_config
#
variable "vpc" {
  description = "(Required). VPC configuration for the CodeBuild project."
  type = object({
    id              = string       # vpc id
    subnets         = list(string) # ids
    security_groups = list(string) # ids
  })
  default = null
}

#
# Fully qualified file system path for a YAML (.yml) based
# shell script that will be executed in the compute environment.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#source
#
variable "script" {
  description = "(Required). Path to the buildspec file for the CodeBuild project."
  type        = string
}

#
# SCM repository configuration.
# Type is compatible with the codepipeline module
#
variable "repo" {
  description = "(Required). SCM code repository settings."
  type = object({
    name      = string
    provider  = optional(string, "CodeCommit")
    region    = optional(string, null)
    role_arn  = optional(string, null)
  })
}

#
# Secrets that this CodeBuild project will have access to.
#
variable "secrets" {
  description = "(Optional). List of secret names that are stored in Secrets Manager which this project will have read access to."
  type        = list(string)
  default     = []
}

#
# List of log group names
#
variable "logs" {
  description = "(Optional). List of log group names which this CodeBuild project has access to."
  type        = list(string)
  default     = []
}

#
# The CICD IAM role ARN when used with CodePipeline.
#
variable "iam_codepipeline" {
  type        = list(string)
  description = "(Optional). The ARN of the CodePipeline IAM role and the policy. Only required if var.stages is set."
  default     = null
}

#
# If using with CodePipeline, a list of all build stages so IAM roles and policies and be generated.
# Will skip "Source" stages if var.repo != null.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline#stage
#
variable "stages" {
  description = "(Required if CodePipeline is being used). List of stages that are being passed to CodePipeline (if used). This list will be used to generate the needed IAM resources. There is no dependency on CodePipeline and, when set, object values in each list item do not override any other input variable."
  default     = null
  type = list(object({
    name   = string
    action = object({
      name            = optional(string, "Build")
      category        = optional(string, "Build")
      provider        = optional(string, "CodeBuild")
      version         = optional(string, "1")
      owner           = optional(string, "AWS")
      region          = optional(string, null)
      input_artifacts = optional(list(string), null)
      configuration   = optional(object({
        ProjectName = optional(string, null)
      }), null)
    })
    resource = optional(object({
      region                    = optional(string, null)
      name                      = optional(string, null)
      description               = optional(string, null)
      script                    = optional(string, null)
      iam_service_role_policies = optional(list(string), [])

      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#environment
      # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
      compute = optional(object({
        compute_type = optional(string, "BUILD_GENERAL1_SMALL")
        image        = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
        type         = optional(string, "LINUX_CONTAINER")
      }))

      # Inherits var.vpc if not set.
      vpc = optional(object({
        id              = optional(string,       null) # vpc id
        subnets         = optional(list(string), null) # ids
        security_groups = optional(list(string), null) # ids
      }), null)
    }), null)
    secrets = optional(list(string), [])
    logs    = optional(list(string), [])
  }))
}