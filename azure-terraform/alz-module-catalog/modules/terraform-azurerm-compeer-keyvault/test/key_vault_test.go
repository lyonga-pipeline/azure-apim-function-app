package test

import (
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/keyvault/mgmt/2019-09-01/keyvault"
	"github.com/Azure/go-autorest/autorest/azure"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAzureKeyVault(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../path_to_your_terraform_code_directory",

		// Set variables for your Terraform code. This can also read from tfvars file.
		Vars: map[string]interface{}{
			"name": "examplevault",
			//... other vars
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Initialize and Apply Terraform code.
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs.
	keyVaultName := terraform.Output(t, terraformOptions, "name")

	// Assert Key Vault exists in Azure.
	assert.True(t, checkKeyVaultExists(t, keyVaultName))
}

func checkKeyVaultExists(t *testing.T, keyVaultName string) bool {
	// Authentication
	clientID := "YOUR_CLIENT_ID"
	clientSecret := "YOUR_CLIENT_SECRET"
	tenantID := "YOUR_TENANT_ID"
	environment := azure.PublicCloud

	clientConfig := auth.NewClientCredentialsConfig(clientID, clientSecret, tenantID)
	authorizer, err := clientConfig.Authorizer()
	if err != nil {
		t.Fatalf("Failed to get Azure authorizer: %v", err)
	}

	keyVaultsClient := keyvault.NewVaultsClientWithBaseURI(environment.ResourceManagerEndpoint, "YOUR_SUBSCRIPTION_ID")
	keyVaultsClient.Authorizer = authorizer

	result, err := keyVaultsClient.Get(t, "YOUR_RESOURCE_GROUP", keyVaultName)
	if err != nil {
		t.Fatalf("Failed to get key vault: %v", err)
	}

	return *result.Name == keyVaultName
}
