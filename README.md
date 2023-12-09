# Terraform AWS/CICD CodeBuild

Set up and manage an [AWS Build](https://aws.amazon.com/codebuild/) to facilitate  [Continuous Integration](https://en.wikipedia.org/wiki/Continuous_integration) and Continuous [Deployments](https://en.wikipedia.org/wiki/Continuous_deployment)/[Delivery](https://en.wikipedia.org/wiki/Continuous_delivery) (CI/CD). Use `var.stages` to define different build stages.

## Prerequisites

- Create an S3 bucket for the CodeBuild caching and pass the name to the module as `var.cache = {location="S3BUCKET"}]`

## Usage

Include the module in your Terraformcode

```terraform
module "codebuild" {
  source    = "https://github.com/clearscale/tf-aws-cicd-codebuild.git"

  accounts = [
    { name = "shared", provider = "aws", key = "shared"}
  ]

  prefix       = "ex"
  client       = "example"
  project      = "aws"
  env          = "dev"
  region       = "us-east-1"
  name         = "codebuild"
  project_name = "RunTerratest"

  repo = {
    name = "my-codecommit-repo"
  }
  stages = [{
    name   = "CodeBuildProjectName"
    action = {
        configuration = {}
    }
  }]
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