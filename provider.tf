#
# Specify which provider(s) this module requires.
# https://developer.hashicorp.com/terraform/language/providers/configuration
#
provider "aws" {
  max_retries = 3
  region      = "us-west-1"
}