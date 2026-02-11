# Clara Train Prerequisites

This document outlines the prerequisites required to successfully deploy NVIDIA Clara Train SDK on Red Hat OpenShift AI.

## Cluster Requirements

### 1. Red Hat OpenShift AI (RHOAI)
- **Version**: 2.x or later
- **Status**: Installed and operational
- **Access**: Dashboard accessible and functional

### 2. GPU Support
- **GPU Operator**: Certified and running
- **Node Feature Discovery (NFD)**: Installed for GPU detection
- **NVIDIA GPU**: Pascal architecture or newer (e.g., V100, A100, L40S, etc.)
- **Minimum GPU Memory**: 16GB VRAM recommended
- **GPU Quantity**: At least 1 GPU available for workloads

### 3. Storage
- **Storage Class**: Available and working (e.g., gp3-csi, gp2, nfs, ceph-rbd)
- **Minimum Capacity**: 100GB available for datasets and models
- **Access Mode**: ReadWriteOnce (RWO) support required

### 4. Cluster Resources
- **CPU**: Minimum 8 vCPU per workload
- **Memory**: Minimum 64GB RAM per workload
- **Nodes**: At least 1 GPU-enabled node

## User Requirements

### 1. NGC API Key
- **Register**: Create account at https://ngc.nvidia.com/
- **Generate Key**: Navigate to Setup → Generate API Key
- **Save**: Store the API key securely (will be added to `.env`)

### 2. Permissions
- **Namespace Admin**: Ability to create resources in target namespace
- **ImageStream Creation**: Permission to create ImageStreams (in user namespace or cluster-wide)
- **Secret Management**: Ability to create docker-registry secrets

### 3. CLI Tools
- **oc CLI**: OpenShift command-line tool installed and configured
  ```bash
  oc version
  oc whoami
  ```
- **helm CLI**: Helm v3.x installed
  ```bash
  helm version
  ```
- **kubectl** (optional): Kubernetes CLI for additional operations

### 4. Authentication
- **Logged In**: Active session to OpenShift cluster
  ```bash
  oc login <cluster-url>
  oc project <namespace>
  ```

## Configuration Requirements

### 1. Environment File (.env)
Located at repository root, must contain:
```bash
NAMESPACE="your-namespace"
NGC_API_KEY="your-ngc-api-key-here"
```

### 2. Network Access
- **NGC Registry**: Access to `nvcr.io` for container pulls
- **Container Size**: Ability to pull ~15GB image (Clara Train SDK)
- **Internet Connectivity**: Required for initial image download

### 3. ImageStream Namespace
- **Default**: Deploys to user's namespace (from .env)
- **Alternative**: Can be configured to deploy to `redhat-ods-applications` for cluster-wide availability
- **Permissions**: Must have ImageStream create permissions in target namespace

## Optional Components

### 1. Triton Inference Server (for AIAA)
- **Purpose**: AI-Assisted Annotation functionality
- **Status**: Disabled by default (requires model repository configuration)
- **GPU Requirement**: 1 additional GPU
- **To Enable**: Set `components.triton.enabled=true` in values or `--set components.triton.enabled=true`
- **Note**: Requires AIAA model setup (see Clara Train AIAA notebooks)

### 2. Custom Storage Class
- **Default**: Uses `gp3-csi`
- **Override**: Can specify different storage class via `--set components.storage.storageClassName=<class>`

## Pre-Installation Checklist

Before running `make install`, verify:

- [ ] RHOAI Dashboard is accessible
- [ ] GPU Operator shows GPUs available (`oc get nodes -l nvidia.com/gpu.present=true`)
- [ ] Storage class exists (`oc get sc`)
- [ ] `.env` file contains valid NAMESPACE and NGC_API_KEY
- [ ] Logged into OpenShift cluster (`oc whoami`)
- [ ] Helm v3.x installed (`helm version`)
- [ ] Network can reach nvcr.io

## Troubleshooting

### ImageStream Import Fails
- **Cause**: Invalid NGC API Key or network issues
- **Solution**: Verify NGC credentials, check network access to nvcr.io
- **Check**: `oc describe imagestream clara-train-workbench`

### PVC Pending
- **Cause**: Storage class not available or insufficient capacity
- **Solution**: Verify storage class exists and has capacity
- **Check**: `oc get pvc`, `oc describe pvc clara-train-storage`

### Triton Pod CrashLoop
- **Cause**: No GPU available or insufficient GPU memory
- **Solution**: Verify GPU availability, check GPU memory
- **Check**: `oc logs deployment/triton-server`

### Permission Denied
- **Cause**: Insufficient RBAC permissions
- **Solution**: Request namespace admin or required permissions from cluster admin
- **Check**: `oc auth can-i create imagestreams`

## Next Steps

After verifying all prerequisites:
1. Configure `.env` file with your values
2. Run `make install` to deploy all components
3. Run `make verify` to check installation
4. Create RHOAI Workbench via Dashboard using Clara Train SDK image
5. Test GPU functionality inside workbench

For detailed installation instructions, see main README.md.
