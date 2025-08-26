26/08
🔐 Security Enhancements:

  1. Added Security Context Constraints (SCCs) for both MCP Server and N8N/PostgreSQL
  2. Non-root execution enforced for all containers
  3. Secure secrets management with environment variables (never committed to git)
  4. PostgreSQL upgraded to version 14-alpine with proper security context

  📦 Key Changes Made:

  1. N8N SCC (agentic/n8n/k8s/n8n-scc.yaml) - Security constraints for N8N
  2. PostgreSQL Security - Updated StatefulSet with non-root user, resource limits, and persistent storage
  3. PostgreSQL ServiceAccount (agentic/n8n/k8s/postgres/pg-serviceaccount.yaml)
  4. Secure Deployment Script (deploy-secure-crc.sh) - Complete automation with security checks
  5. Secrets Template (.env.secrets.template) - Template for secure credential management
  6. Comprehensive Documentation (CRC_DEPLOYMENT_GUIDE.md) - Full deployment and troubleshooting guide

  🚀 Quick Deployment:

  # 1. Copy and configure secrets
  cp .env.secrets.template .env.secrets
  # Edit .env.secrets with your credentials

  # 2. Deploy everything
  ./deploy-secure-crc.sh

  🔧 What's Different from AKS:

  - Routes instead of Ingress (OpenShift-native)
  - Security Context Constraints instead of Pod Security Policies
  - ServiceAccount-based authentication for in-cluster access
  - CRC-specific hostnames (*.apps-crc.testing)
  - No external kubeconfig needed (uses ServiceAccount)

  The deployment is now fully secured, uses non-root containers, has proper resource limits, and includes comprehensive error handling and logging. All secrets are managed externally and never committed to
  the repository.

