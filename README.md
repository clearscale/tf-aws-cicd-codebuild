# Terraform AWS/CICD CodeBuild

`NOTE:` Use [tf-aws-cicd](https://github.com/clearscale/tf-aws-cicd) instead of using this module directly.

Set up and manage an [AWS Build](https://aws.amazon.com/codebuild/) to facilitate  [Continuous Integration](https://en.wikipedia.org/wiki/Continuous_integration) and Continuous [Deployments](https://en.wikipedia.org/wiki/Continuous_deployment)/[Delivery](https://en.wikipedia.org/wiki/Continuous_delivery) (CI/CD). Use `var.stages` to define different build stages.

## Prerequisites

See [tf-aws-cicd](https://github.com/clearscale/tf-aws-cicd)

## Usage

Include the module in your Terraformcode

```terraform
locals {

  repo_name = "test"
  repo_role = "arn:aws:iam::123456789012:role/CsTffwkcs.Shared.USW1.CodeCommit.Test"

  # Format for CodeBuild module
  stages = [{
    name   = "Plan"
    action = {
      provider      = "CodeBuild"
      configuration = {
        ProjectName = (
          "plan"
        )
      }
    }
    resource = {
      description = "CICDTEST: Plan project resources."
      script      = "plan.yml"
      compute = {
        compute_type = "BUILD_GENERAL1_SMALL"
        image        = "aws/codebuild/standard:6.0-22.06.30" # "ACCOUNTID.dkr.ecr.REGION.amazonaws.com/ecr-repo:latest"
        type         = "LINUX_CONTAINER"
      }
    }
  }, {
    name   = "Apply"
    action = {
      provider      = "CodeBuild"
      configuration = {
        ProjectName = (
          "apply"
        )
      }
    }
    resource = {
      description = "CICDTEST: Apply project resources."
      script      = "plan.yml"
      compute = {
        compute_type = "BUILD_GENERAL1_SMALL"
        image        = "aws/codebuild/standard:6.0-22.06.30" # "ACCOUNTID.dkr.ecr.REGION.amazonaws.com/ecr-repo:latest"
        type         = "LINUX_CONTAINER"
      }
    }
  }]
}

module "codebuild" {
  source    = "github.com/clearscale/tf-aws-cicd-codebuild.git?ref=v1.0.0"

  account = {
    id = "*", name = local.account.name, provider = "aws", key = "current", region = local.region.name
  }


  prefix  = local.context.prefix
  client  = local.context.client
  project = local.context.project
  env     = local.account.name
  region  = local.region.name
  name    = "codebuild"

  # Keep the project_name simple. Try to keep it consistent with the CodeCommit repo and CodePipeline name.
  project_name = "test"
  script       = "${abspath(path.module)}/scripts/plan.yml"
  repo         = { name = local.repo_name }
  
  # Only needed if CodePipeline is being used. The CodePipeline stages need to be passed to CodeBuild
  # so the required IAM resources can be generated.
  # stages = [{
  #   name   = "CbTest"
  #   action = {
  #       configuration = {}
  #   }
  # }]

  stages = local.stages

  # The default VPC. Can be overridden in each var.vpc.stages[x].vpc.
  vpc = {
    id              = "VPC_ID"
    subnets         = ["SUBNET_ID_1", "SUBNET_ID_2"]
    security_groups = ["SG_ID_1", "SG_ID_2"],
  }
}
```

## Plan

```bash
terraform plan -var='repo={name="my-codecommit-repo"}' -var='script=./test/build.yml' -var='vpc=null' -var='stages=[{name="CodeBuildProjectName",action={configuration={}}}]' -var='project_name=RunTerratest'
```

## Apply

```bash
terraform apply -var='repo={name="my-codecommit-repo"}' -var='script=./test/build.yml' -var='vpc=null' -var='stages=[{name="CodeBuildProjectName",action={configuration={}}}]' -var='project_name=RunTerratest'
```

## Destroy

```bash
terraform destroy -var='repo={name="my-codecommit-repo"}' -var='script=./test/build.yml' -var='vpc=null' -var='stages=[{name="CodeBuildProjectName",action={configuration={}}}]' -var='project_name=RunTerratest'
```
## TODO

Fix IAM permissions in iam.tf. For example,

```
  statement {
    sid       = ""
    resources = ["*"]
    effect  = "Allow"
    actions = [
      "iam:*",
      "codecommit:*",
      "codepipeline:*",
      "codebuild:*",
      "logs:*",
      "s3:*",
      "secretsmanager:*",
      "glue:*",
      "ec2:*",
      "dynamodb:*",
      "lakeformation:*",
      "cloudtrail:DescribeTrails",
      "cloudtrail:LookupEvents"
    ]
  }
```

These permissions were added and created while testing the inital deployment of a project and are too open. Also, cleanup the other permissions in the policy.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_std"></a> [std](#module\_std) | github.com/clearscale/tf-standards.git | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cb_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnets.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | (Optional). Cloud provider account object. | <pre>object({<br>    key      = optional(string, "current")<br>    provider = optional(string, "aws")<br>    id       = optional(string, "*") <br>    name     = string<br>    region   = optional(string, null)<br>  })</pre> | <pre>{<br>  "id": "*",<br>  "name": "shared"<br>}</pre> | no |
| <a name="input_cache"></a> [cache](#input\_cache) | (Optional). Cache store | <pre>object({<br>    type      = optional(string, "S3")<br>    location  = optional(string, null)<br>    modes     = optional(list(string), [])<br>  })</pre> | `null` | no |
| <a name="input_client"></a> [client](#input\_client) | (Optional). Name of the client | `string` | `"ClearScale"` | no |
| <a name="input_compute"></a> [compute](#input\_compute) | (Optional). Environment (Compute Resource) configuration for the CodeBuild project. | <pre>object({<br>    compute_type = optional(string, "BUILD_GENERAL1_SMALL")<br>    image        = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")<br>    type         = optional(string, "LINUX_CONTAINER")<br>  })</pre> | <pre>{<br>  "compute_type": "BUILD_GENERAL1_SMALL",<br>  "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",<br>  "type": "LINUX_CONTAINER"<br>}</pre> | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional). Description of the CodeBuild project. | `string` | `"A CodeBuild project brought to you by ClearScale."` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | (Optional). KMS key ARN. | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | (Optional). Name of the current environment. | `string` | `"dev"` | no |
| <a name="input_iam_codepipeline"></a> [iam\_codepipeline](#input\_iam\_codepipeline) | (Optional). The ARN of the CodePipeline IAM role and the policy. Only required if var.stages is set. | `list(string)` | `null` | no |
| <a name="input_iam_service_role_policies"></a> [iam\_service\_role\_policies](#input\_iam\_service\_role\_policies) | (Optional). List of IAM policy ARNs to attach to the primary service role. | `list(string)` | `[]` | no |
| <a name="input_logs"></a> [logs](#input\_logs) | (Optional). List of log group names which this CodeBuild project has access to. | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional). The name of the CodeBuild project. Used to add additional context to dependency resources like IAM roles. Project name should be added to var.project\_name. | `string` | `"codebuild"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | (Optional). Prefix override for all generated naming conventions. | `string` | `"cs"` | no |
| <a name="input_project"></a> [project](#input\_project) | (Optional). Name of the client project. | `string` | `"pmod"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | (Required). Unrelated to var.project and var.name. This represents the name of the CodeBuild Project. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional). AWS region. | `string` | `"us-west-1"` | no |
| <a name="input_repo"></a> [repo](#input\_repo) | (Required). SCM code repository settings. | <pre>object({<br>    name      = string<br>    provider  = optional(string, "CodeCommit")<br>    region    = optional(string, null)<br>    role_arn  = optional(string, null)<br>  })</pre> | n/a | yes |
| <a name="input_script"></a> [script](#input\_script) | (Required). Path to the buildspec file for the CodeBuild project. | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (Optional). List of secret names that are stored in Secrets Manager which this project will have read access to. | `list(string)` | `[]` | no |
| <a name="input_stages"></a> [stages](#input\_stages) | (Required if CodePipeline is being used). List of stages that are being passed to CodePipeline (if used). This list will be used to generate the needed IAM resources. There is no dependency on CodePipeline and, when set, object values in each list item do not override any other input variable. | <pre>list(object({<br>    name   = string<br>    action = object({<br>      name            = optional(string, "Build")<br>      category        = optional(string, "Build")<br>      provider        = optional(string, "CodeBuild")<br>      version         = optional(string, "1")<br>      owner           = optional(string, "AWS")<br>      region          = optional(string, null)<br>      input_artifacts = optional(list(string), null)<br>      configuration   = optional(object({<br>        ProjectName = optional(string, null)<br>      }), null)<br>    })<br>    resource = optional(object({<br>      region                    = optional(string, null)<br>      name                      = optional(string, null)<br>      description               = optional(string, null)<br>      script                    = optional(string, null)<br>      iam_service_role_policies = optional(list(string), [])<br><br>      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#environment<br>      # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html<br>      compute = optional(object({<br>        compute_type = optional(string, "BUILD_GENERAL1_SMALL")<br>        image        = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")<br>        type         = optional(string, "LINUX_CONTAINER")<br>      }))<br><br>      # Inherits var.vpc if not set.<br>      vpc = optional(object({<br>        id              = optional(string,       null) # vpc id<br>        subnets         = optional(list(string), null) # ids<br>        security_groups = optional(list(string), null) # ids<br>      }), null)<br>    }), null)<br>    secrets = optional(list(string), [])<br>    logs    = optional(list(string), [])<br>  }))</pre> | `null` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | (Required). VPC configuration for the CodeBuild project. | <pre>object({<br>    id              = string       # vpc id<br>    subnets         = list(string) # ids<br>    security_groups = list(string) # ids<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the CodeBuild project. |
| <a name="output_badge_url"></a> [badge\_url](#output\_badge\_url) | The ARN of the CodeBuild project. |
| <a name="output_id"></a> [id](#output\_id) | Name (if imported via name) or ARN (if created via Terraform or imported via ARN) of the CodeBuild project. |
| <a name="output_name"></a> [name](#output\_name) | The name of the CodeBuild project. |
| <a name="output_public_project_alias"></a> [public\_project\_alias](#output\_public\_project\_alias) | The project identifier used with the public build APIs.. |
| <a name="output_role"></a> [role](#output\_role) | Service role information. |
| <a name="output_stage_roles"></a> [stage\_roles](#output\_stage\_roles) | Role names of all the CodePipeline stages that were specified as var.stages. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | All tags applied to the CodeBuild project. |
<!-- END_TF_DOCS -->