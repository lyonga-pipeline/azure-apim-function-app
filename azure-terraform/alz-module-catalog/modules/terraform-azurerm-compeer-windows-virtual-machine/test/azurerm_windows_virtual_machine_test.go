package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAzureWindowsVM(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: ".",
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndPlan(t, terraformOptions)

	terraform.ApplyAndIdempotent(t, terraformOptions)

	// Run `terraform output` to get the values of output variables and check they have the expected values.
	// output := terraform.Output(t, terraformOptions, "vnet_address_space")
	// assert.Equal(t, "10.100.6.0/23", output)
}
