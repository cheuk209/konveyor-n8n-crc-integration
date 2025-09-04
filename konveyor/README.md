# Konveyor Deployment for CRC

This directory contains the Kubernetes manifests and deployment scripts for running Konveyor on OpenShift CRC.

## Directory Structure

```
konveyor/
├── base/                       # Base Konveyor operator resources
│   ├── namespace.yaml         # Konveyor namespace
│   ├── catalog-source.yaml    # Operator catalog
│   ├── konveyor-operator-group.yaml
│   ├── konveyor-subscription.yaml
│   └── kustomization.yaml
├── overlays/
│   └── crc/                   # CRC-specific optimizations
│       ├── tackle-cr.yaml    # Resource-constrained Tackle CR
│       └── kustomization.yaml
├── deploy-konveyor-crc.sh    # Automated deployment script
└── README.md
```

## Quick Deploy

```bash
# Make script executable
chmod +x deploy-konveyor-crc.sh

# Deploy Konveyor
./deploy-konveyor-crc.sh
```

## Manual Deployment

```bash
# Deploy operator
oc apply -k base/

# Wait for operator to be ready (check CSV status)
oc get csv -n konveyor-tackle

# Deploy Tackle instance
oc apply -k overlays/crc/
```

## CRC Optimizations

The CRC overlay includes:
- Reduced memory and CPU limits
- Smaller persistent volume sizes
- Disabled optional features (pathfinder)
- Minimal resource requirements preset

## Access Konveyor

```bash
# Get the route
oc get route -n konveyor-tackle tackle

# Default credentials
Username: admin
Password: Passw0rd!
```

## Troubleshooting

```bash
# Check operator logs
oc logs -n konveyor-tackle -l app.kubernetes.io/name=tackle-operator

# Check Tackle status
oc get tackle -n konveyor-tackle -o yaml

# Check all pods
oc get pods -n konveyor-tackle

# Describe Tackle resource
oc describe tackle tackle -n konveyor-tackle
```

## Cleanup

```bash
# Remove everything
oc delete namespace konveyor-tackle
oc delete catalogsource konveyor -n openshift-marketplace
```