# 🔒 Secure Deployment Guide

## Overview
All sensitive information has been removed from the repository and stored locally. This guide explains how to deploy the application securely.

## Sensitive Data Location
- **`.env.secrets`** - Contains all extracted credentials (git-ignored)
- **`.secrets/`** - Contains backup files like kubeconfig (git-ignored)

## How to Use Secrets Securely

### 1. Load Environment Variables
```bash
# Load secrets into your shell session
source .env.secrets
```

### 2. Create Kubernetes Secrets Dynamically

#### Container Registry Secret
```bash
kubectl create secret docker-registry quay-io-dkcapgemini \
  --docker-server=quay.io \
  --docker-username=$QUAY_USERNAME \
  --docker-password=$QUAY_PASSWORD \
  --namespace=k8smcp

kubectl create secret docker-registry quay-io-dkcapgemini \
  --docker-server=quay.io \
  --docker-username=$QUAY_USERNAME \
  --docker-password=$QUAY_PASSWORD \
  --namespace=n8n
```

#### Database Secrets
```bash
kubectl create secret generic postgres-secrets \
  --from-literal=POSTGRES_USER=$POSTGRES_USER \
  --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  --from-literal=POSTGRES_DB=$POSTGRES_DB \
  --namespace=n8n

kubectl create secret generic n8n-secrets \
  --from-literal=DB_POSTGRESDB_PASSWORD=$POSTGRES_PASSWORD \
  --from-literal=N8N_BASIC_AUTH_USER=$N8N_BASIC_AUTH_USER \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD \
  --from-literal=N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY \
  --namespace=n8n
```

### 3. For Azure AKS Clusters
```bash
# Get credentials directly from Azure (don't save to file)
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --overwrite-existing

# Or for temporary use:
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --file /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
# Remember to delete after use: rm /tmp/kubeconfig
```

### 4. For OpenShift CRC
```bash
# CRC doesn't need external kubeconfig
crc start
eval $(crc oc-env)
oc login -u kubeadmin -p $(crc console --credentials | grep kubeadmin | awk '{print $NF}')
```

## Deployment Script Template

Create a `deploy-secure.sh` script:

```bash
#!/bin/bash

# Load secrets
source .env.secrets

# Create namespaces
kubectl create namespace k8smcp --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace n8n --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
echo "Creating secrets..."
kubectl create secret docker-registry quay-io-dkcapgemini \
  --docker-server=quay.io \
  --docker-username=$QUAY_USERNAME \
  --docker-password=$QUAY_PASSWORD \
  --namespace=k8smcp --dry-run=client -o yaml | kubectl apply -f -

# Deploy applications
echo "Deploying MCP Server..."
kubectl apply -k agentic/mcp/k8s/

echo "Deploying N8N..."
kubectl apply -k agentic/n8n/k8s/
```

## Security Best Practices

### DO's ✅
- Use environment variables for local development
- Create secrets at deployment time
- Use external secret management (Azure Key Vault, HashiCorp Vault)
- Rotate credentials regularly
- Use ServiceAccounts for in-cluster authentication

### DON'Ts ❌
- Never commit `.env.secrets` or `.secrets/` directory
- Never hardcode credentials in YAML files
- Never share kubeconfig files via git
- Never use weak passwords in production

## Alternative: Using External Secrets Operator

For production, consider using External Secrets Operator with Azure Key Vault:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-keyvault
spec:
  provider:
    azurekv:
      vaultUrl: "https://your-keyvault.vault.azure.net"
      authType: ManagedIdentity
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  secretStoreRef:
    name: azure-keyvault
  target:
    name: postgres-secrets
  data:
  - secretKey: POSTGRES_PASSWORD
    remoteRef:
      key: postgres-password
```

## Credential Rotation Checklist

After cleaning git history, immediately:

- [ ] Change Quay.io password
- [ ] Regenerate Azure AKS cluster credentials
- [ ] Update all database passwords
- [ ] Generate new N8N encryption key
- [ ] Update any CI/CD pipelines with new credentials
- [ ] Notify team members about repository history rewrite

## Questions?

If you need to access the original kubeconfig for reference (before rotating credentials):
```bash
cat .secrets/kubeconfig-backup.yaml
```

Remember: This file contains compromised credentials and should only be used to identify which clusters need credential rotation.