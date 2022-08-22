resource "azurerm_resource_group" "rg" {
  name      = var.resource_group_name
  location  = var.location
}

# Create user assigned identity
resource "azurerm_user_assigned_identity" "umi" {
  name                = "umi"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Used to retrive the Tentant Id
data "azurerm_client_config" "current" {}

# Ignore this section - Test case with a dummy Azure Key Vault
resource "azurerm_key_vault" "akv_xpto" {
  name                        = "akv-xpto"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id 
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

# Ignore this section - Test Cluster
resource "azurerm_kubernetes_cluster" "k8s" {
    name                    = var.cluster_name
    location                = azurerm_resource_group.rg.location
    resource_group_name     = azurerm_resource_group.rg.name
    dns_prefix              = var.cluster_name
    kubernetes_version      = var.kubernetes_version
    private_cluster_enabled = var.private_cluster_enabled

    default_node_pool {
        name            = "agentpool"
        node_count      = var.node_count
        vm_size         = var.vm_size
    }

    identity {
        type = "UserAssigned" # 
        identity_ids = [azurerm_user_assigned_identity.umi.id]
    }

    network_profile {
        load_balancer_sku = "standard"
        network_plugin = "kubenet"
    }

    key_vault_secrets_provider {
        secret_rotation_enabled = true
        secret_rotation_interval = "2m"
    }

    tags = {
        Environment = "lab"
    }
}

resource "azurerm_role_assignment" "akv_kubelet" {
  scope                = azurerm_key_vault.akv_xpto.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
}

resource "azurerm_key_vault_access_policy" "akv_access_kubelet" {
    key_vault_id = azurerm_key_vault.akv_xpto.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
    object_id    = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id

    key_permissions = [
        "Get"
    ]

    secret_permissions = [
        "Get"
    ]

    certificate_permissions = [
        "Get"
    ]
}