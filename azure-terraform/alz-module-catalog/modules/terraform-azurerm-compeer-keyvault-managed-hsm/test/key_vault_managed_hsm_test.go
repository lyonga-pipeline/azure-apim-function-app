package test

import (
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/preview/keyvault/mgmt/2020-04-01-preview/keyvault"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAzureManagedHSM(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../path_to_your_terraform_code_directory",

		Vars: map[string]interface{}{
			"name": "test-hsm",
			// ... other necessary variables
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	managedHSMName := terraform.Output(t, terraformOptions, "name")

	// Assert the Managed HSM resource is created in Azure.
	assert.True(t, checkManagedHSMExists(t, managedHSMName))
}

func checkManagedHSMExists(t *testing.T, managedHSMName string) bool {
	clientID := "YOUR_CLIENT_ID"
	clientSecret := "YOUR_CLIENT_SECRET"
	tenantID := "YOUR_TENANT_ID"

	clientConfig := auth.NewClientCredentialsConfig(clientID, clientSecret, tenantID)
	authorizer, err := clientConfig.Authorizer()
	if err != nil {
		t.Fatalf("Failed to get Azure authorizer: %v", err)
	}

	managedHSMClient := keyvault.NewManagedHSMsClient("YOUR_SUBSCRIPTION_ID")
	managedHSMClient.Authorizer = authorizer

	_, err = managedHSMClient.Get(t, "YOUR_RESOURCE_GROUP", managedHSMName)
	if err != nil {
		t.Fatalf("Failed to get managed HSM: %v", err)
		return false
	}

	return true
}
