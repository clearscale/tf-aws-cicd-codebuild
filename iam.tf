locals {
  iam_stage_roles = (local.stages == null ? [] : flatten([[
    for stage in local.stages :
      flatten([[
        "arn:aws:iam::${var.account.id}:role/${local.context.aws[0].prefix.dot.full.function}",
        "arn:aws:iam::${var.account.id}:policy/${local.context.aws[0].prefix.dot.full.function}"
      ], (var.iam_codepipeline != null)
        ? var.iam_codepipeline
        : []
      ])
      if try(trimspace(lower(stage.action.provider)), "error") == "codebuild"
  ]]))
}

resource "aws_iam_role" "this" {
  name = local.context.aws[0].prefix.dot.full.function

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "",
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })

  lifecycle {
    ignore_changes = [
      tags, tags_all
    ]
  }
}

data "aws_iam_policy_document" "this" {

  # https://docs.aws.amazon.com/lake-formation/latest/dg/permissions-reference.html
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

  statement {
    sid       = "AllowInteractionBetweenCPStages"
    effect    = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:DetachRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:ListPolicyVersions",
    ]
    resources = local.iam_stage_roles
  }

  statement {
    sid       = "MainServiceRole"
    resources = flatten([[
      "arn:aws:codebuild:${var.region}:${var.account.id}:project/${local.cb_project_name}",
    ],[
      for secret in var.secrets : [
        "arn:aws:secretsmanager:${var.region}:${var.account.id}:secret:${secret}-*",
      ]
    ],[
      for log in var.logs : [
        "arn:aws:logs:${var.region}:${var.account.id}:log-group:${log}:*",
      ]
    ],[
      for subnet in local.vpc_config.subnets : [
        "arn:aws:ec2:${var.region}:${var.account.id}:subnet/${subnet}",
      ]
    ],[
      for sg in local.vpc_config.security_group_ids : [
        "arn:aws:ec2:${var.region}:${var.account.id}:security-group/${sg}",
      ]
    ],[((lower(trimspace(var.repo.provider)) == "codecommit"
        && var.repo.role_arn != null
        && local.account_codecommit != true
      ) ? [(var.repo.region != null
            ? "arn:aws:codecommit:${var.repo.region}:${local.account_codecommit}:${var.repo.name}"
            : "arn:aws:codecommit:${var.region}:${local.account_codecommit}:${var.repo.name}"
          )]
        : []
      )
    ],[
      for bucket in local.bucket_names : [
        "arn:aws:s3:::${bucket}",
        "arn:aws:s3:::${bucket}/*",
      ]
    ]])
    effect  = "Allow"
    actions = [
      "codecommit:GitPull",
      "codecommit:Get*",
      "codecommit:List*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "secretsmanager:GetSecretValue",
      "iam:PassRole",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
  }
}

resource "aws_iam_policy" "this" {
  name        = local.context.aws[0].prefix.dot.full.function
  description = "Default '${local.name}' CodeBuild policy for the '${local.project}' project."
  path        = "/"
  policy      = data.aws_iam_policy_document.this.json

  lifecycle {
    ignore_changes = [
      tags, tags_all
    ]
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.id
}

resource "aws_iam_role_policy_attachment" "cb_attachment" {
  count      = length(local.iam_service_role_policies)
  policy_arn = local.iam_service_role_policies[count.index]
  role       = aws_iam_role.this.id
}