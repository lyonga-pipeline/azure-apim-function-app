package test

import (
	"context"
	"testing"

	"github.com/Azure/azure-sdk-for-go/profiles/latest/keyvault/mgmt/keyvault"
	"github.com/Azure/go-autorest/autorest/azure"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAzureKeyVaultResources(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../path_to_your_terraform_code_directory",

		Vars: map[string]interface{}{
			"create_secret": true,
			// ... other necessary variables
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name") // Ensure this output is defined in your Terraform code.

	// Assert resources are created in Azure.
	assert.True(t, checkKeyVaultResourceExists(t, keyVaultName, "secret"))
	assert.True(t, checkKeyVaultResourceExists(t, keyVaultName, "key"))
	// ... Repeat for other resources.
}

func checkKeyVaultResourceExists(t *testing.T, keyVaultName string, resourceType string) bool {
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

	ctx := context.Background() // Create a context.

	// This function is an example. You might need to adjust or create separate functions for each resource type.
	// Check the Azure SDK for the specific functions to get each type of resource.

	result, err := keyVaultsClient.Get(ctx, "YOUR_RESOURCE_GROUP", keyVaultName)
	if err != nil {
		t.Fatalf("Failed to get key vault: %v", err)
	}

	return *result.Name == keyVaultName // Adjust the check for the specific resource.
}
