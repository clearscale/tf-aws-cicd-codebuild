package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/codebuild"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

/**
 * Using default variables
 * TODO: Test the rest of the values
 */
func TestTerraformCodeBuildProject(t *testing.T) {
	uniqueId := random.UniqueId()
	region := "us-west-1"
	repoName := fmt.Sprintf("my-codecommit-repo%s", strings.ToLower(uniqueId))
	//s3_bucket := strings.ToLower(fmt.Sprintf("cs-testing-artifacts-%s", uniqueId))

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			// "cache": []map[string]interface{}{
			// 	{
			// 		"location": s3_bucket,
			// 	},
			// },
			"repo": map[string]interface{}{
				"name": repoName,
			},
			"script":       "./test/build.yml",
			"project_name": fmt.Sprintf("RunTerratest%s", strings.ToLower(uniqueId)),
			"stages": []map[string]interface{}{
				{
					"name": "CodeBuildProjectName",
					"action": map[string]interface{}{
						"configuration": map[string]interface{}{},
					},
				},
			},
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	output := terraform.OutputMap(t, terraformOptions, "role")

	// Dash notation
	expectedRoleName := fmt.Sprintf("CsPmod.Shared.Uswest1.Dev.CodeBuild.Runterratest%s",
		strings.ToLower(uniqueId),
	)
	assert.Equal(t, expectedRoleName, output["name"])

	// Get the name of the CodeBuild from Terraform output
	codeBuildProjectName := terraform.Output(t, terraformOptions, "name")

	// Create an AWS session
	awsSession, err := session.NewSessionWithOptions(session.Options{
		Profile:           "default",
		Config:            aws.Config{Region: aws.String(region)},
		SharedConfigState: session.SharedConfigEnable,
	})
	if err != nil {
		t.Fatalf("Failed to create AWS session: %v", err)
	}

	// Create a CodeBuild client
	codeBuildClient := codebuild.New(awsSession)

	// Call the CodeBuild BatchGetProjects API
	resp, err := codeBuildClient.BatchGetProjects(&codebuild.BatchGetProjectsInput{
		Names: []*string{aws.String(codeBuildProjectName)},
	})

	// Assert that there was no error and the project exists
	assert.NoError(t, err, "Error fetching CodeBuild project")
	assert.NotEmpty(t, resp.Projects, "CodeBuild project does not exist or is not found")
}
