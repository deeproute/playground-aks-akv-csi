# Playground for Azure Key Vault CSI in AKS

## Create Infrastructure

```sh
cd playground-aks-akv-csi/terraform
terraform apply
```

This will create the following:
- User Managed Identity
- Azure Key Vault
- Azure Key Vault Access Policies
- AKS


## Create dummy secrets


## AKS Config

```sh
az aks get-credentials --admin -g playground-aks-akv-csi -n aks-akv-csi --overwrite-existing
```

- Get the Tenant ID and the User Managed Identity ID
```
az account list | jq -r '.[] | { name: .name, tentantId: .tenantId }'

az aks show -g playground-aks-akv-csi -n aks-akv-csi --query identityProfile.kubeletidentity.objectId -o tsv
# az identity show -g playground-aks-akv-csi -n umi | jq -r '{ clientId }'
```

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-user-msi
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true" # Set to true for using managed identity
    tenantId: 570057f4-73ef-41c8-bcbb-08db2fc15c2b
    userAssignedIdentityID: 4578adae-9017-4607-b95a-6532e3a94f16 # Set the clientID of the user-assigned managed identity to use
    keyvaultName: akv-xpto
    cloudName: ""
    objects:  |
      array:
        - |
          objectName: secret1
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
        - |
          objectName: key1
          objectType: key
          objectVersion: ""
        - |
          objectName: cert1
          objectType: cert
          objectVersion: ""
        
```

Create the SecretProviderClass:
```sh
playground-aks-akv-csi/yamls$ k apply -f secretproviderclass.yaml 
secretproviderclass.secrets-store.csi.x-k8s.io/azure-kvname-user-msi created
```

- Create the pod who uses the secrets:
```sh
playground-aks-akv-csi/yamls$ k apply -f pod.yaml 
pod/busybox-secrets-store-inline-user-msi created
```

## How to configure Workload Identity in AKS
https://blog.baeke.info/2022/01/31/kubernetes-workload-identity-with-aks/

## How to configure AKV CSI
https://medium.com/dzerolabs/kubernetes-saved-today-f-cked-tomorrow-a-rant-azure-key-vault-secrets-%C3%A0-la-kubernetes-fc3be5e65d18
https://gist.github.com/avillela/3ff18b3bde4347ced4a0917bb70c90dd


## How to enable AKV CSI in Terraform
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#secret_rotation_enabled


## Sealed Secrets
https://betterprogramming.pub/encrypting-kubernetes-secrets-with-sealed-secrets-fe363149a211


## AKS Identity

az aks create -g test-aks -n aks-identity --enable-managed-identity 

## How to convert certificates to different formats
https://stackoverflow.com/questions/13732826/convert-pem-to-crt-and-key

