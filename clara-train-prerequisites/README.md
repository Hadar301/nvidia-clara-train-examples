# Clara Train Prerequisites

This directory contains the installation tooling for NVIDIA Clara Train SDK prerequisites on Red Hat OpenShift AI.

## Overview

This Helm chart and Makefile setup automates the deployment of:
- **NGC Registry Secret**: Authentication for NVIDIA container registry
- **Custom Clara Train Image**: Modified Clara Train SDK v4.1 with GPU compatibility fixes for newer architectures
- **ImageStream**: Makes the custom image available for RHOAI workbenches

**Note**: Storage (PVC) is automatically created by RHOAI when you create a workbench - no pre-provisioning needed.

### Why a Custom Image is Required

The official `nvcr.io/nvidia/clara-train-sdk:v4.1` cannot run on newer GPU architectures (Ada Lovelace and later, including L40S, L40, H100, etc.) due to two critical incompatibilities. Our custom image ([Containerfile](Containerfile)) solves both issues.

#### Problem 1: GPU Architecture Incompatibility
- **Issue**: Clara Train SDK v4.1 (October 2021) has a GPU architecture whitelist that only recognizes Ampere GPUs and older
- **Newer GPUs**: Ada Lovelace (L40S, L40), Hopper (H100), and newer architectures are not recognized
- **Error**: Container fails to start with `ERROR: No supported GPU(s) detected to run this container`
- **Fix**: Custom image clears the `ENTRYPOINT` to bypass the GPU validation script

#### Problem 2: CUDA Driver Compatibility
- **Issue**: Base image contains CUDA compat libraries for driver 470.x, but modern clusters run driver 580.x+
- **Symptom**: Container starts but `torch.cuda.is_available()` returns `False` even though `nvidia-smi` works
- **Root Cause**: Outdated `/usr/local/cuda/compat/lib/libcuda.so.470.57.02` conflicts with host driver
- **Fix**: Custom image removes incompatible compat libraries and prioritizes host driver libraries from GPU Operator

#### What the Custom Image Does
The [Containerfile](Containerfile) applies critical fixes:

1. **Bypasses GPU architecture check** - Removes the validation script that rejects newer GPU architectures
2. **Fixes CUDA driver compatibility** - Removes outdated CUDA compat libraries and configures the container to use host driver libraries (580.x+)
3. **Configures Jupyter for RHOAI** - Sets proper base URL, writable directories, and authentication for OpenShift AI integration

**Without this custom image**: The Clara Train SDK container would refuse to start on newer GPUs, and even if forced to start, PyTorch would not be able to detect or use the GPU.

## Quick Start

### 1. Prerequisites

Before installation, review [prerequisites.md](prerequisites.md) to ensure your cluster meets all requirements.

**Required:**
- Red Hat OpenShift AI installed
- GPU Operator running
- NGC API Key from https://ngc.nvidia.com/
- `oc` and `helm` CLIs installed
- Active OpenShift session

### 2. Configure Environment

Ensure the `.env` file in the repository root is configured:

```bash
NAMESPACE="your-namespace"
NGC_API_KEY="your-ngc-api-key"
```

### 3. Install Prerequisites

```bash
cd clara-train-prerequisites
make install
```

This will deploy the core components to your namespace:
- NGC Registry Secret
- Clara Train ImageStream

### 4. Verify Installation

```bash
make verify
```

Wait for the ImageStream to import (~10-15 minutes for the 15GB image).

### 5. Create RHOAI Workbench

1. Navigate to RHOAI Dashboard
2. Create or select a Data Science Project
3. Create a new Workbench:
   - **Image**: Clara Train SDK (v4.1) - **MUST use the custom image from the ImageStream**
   - **GPU**: 1 nvidia.com/gpu
   - **CPU**: 16 cores
   - **Memory**: 64GB
   - **Storage**: Create new persistent storage (100GB recommended)

**CRITICAL**: You **must** use the Clara Train SDK image from the ImageStream created by this installation. Do **NOT** use the official `nvcr.io/nvidia/clara-train-sdk:v4.1` image directly, as it:
- Will fail to start on newer GPU architectures (architecture whitelist rejection)
- Cannot detect GPUs in PyTorch even if it starts (driver compatibility issues)

The ImageStream provides the custom image with all necessary fixes applied.

### 6. Test GPU Functionality

Inside the workbench terminal:

```bash
bash scripts/test-gpu.sh
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make help` | Display available commands and environment status |
| `make install` | Install all prerequisites |
| `make install-secret` | Install NGC registry secret only |
| `make install-imagestream` | Install Clara Train ImageStream only |
| `make verify` | Verify installation status |
| `make clean` | Remove all installed components |

## Directory Structure

```
clara-train-prerequisites/
├── Makefile                           # Installation orchestration
├── README.md                          # This file
├── prerequisites.md                   # Detailed prerequisites documentation
├── Containerfile                      # Custom Clara Train image with GPU fixes
├── helm/
│   └── clara-train/
│       ├── Chart.yaml                 # Helm chart metadata
│       ├── values.yaml                # Configuration values
│       └── templates/
│           ├── _helpers.tpl           # Template helpers
│           ├── secret.yaml            # NGC registry secret
│           ├── pvc.yaml               # Storage PVC
│           └── imagestream.yaml       # Clara Train ImageStream
└── scripts/
    ├── verify-installation.sh         # Post-install verification
    └── test-gpu.sh                    # GPU functionality test
```

## Customization

### Deploy ImageStream Cluster-Wide

```bash
make install --set components.imagestream.namespace=redhat-ods-applications
```

## Component Details

### NGC Registry Secret
- **Name**: `ngc-secret`
- **Type**: `kubernetes.io/dockerconfigjson`
- **Purpose**: Authenticate to NVIDIA Container Registry (nvcr.io)

### ImageStream
- **Name**: `clara-train-workbench`
- **Base Image**: `nvcr.io/nvidia/clara-train-sdk:v4.1` (modified via Containerfile)
- **Custom Image**: `quay.io/hacohen/clara-sdk:v4.1` (default in values.yaml)
- **Size**: ~16GB
- **Import Time**: 10-15 minutes
- **Purpose**: Notebook image for RHOAI workbenches with GPU compatibility for newer architectures

**Why Custom Image?**
The ImageStream references a custom-built image that fixes two critical issues:
1. **GPU Architecture Compatibility**: Bypasses the Clara Train GPU whitelist that rejects newer GPU architectures (Ada Lovelace, Hopper, and newer)
2. **CUDA Driver Compatibility**: Removes outdated CUDA compat libraries (driver 470.x) and uses host driver libraries (580.x+)

See the [Containerfile](Containerfile) for implementation details.

## Troubleshooting

### ImageStream Import Fails
**Symptoms**: ImageStream exists but no tags imported

**Solution**:
```bash
# Check import status
oc describe imagestream clara-train-workbench -n <namespace>

# Verify NGC secret
oc get secret ngc-secret -n <namespace>

# Check network access to nvcr.io
curl -I https://nvcr.io
```

### GPU Not Available in Workbench
**Symptoms**: `torch.cuda.is_available()` returns False even though `nvidia-smi` works

**Common Causes**:

1. **Using Official NVIDIA Image Instead of Custom Image** (Most Common):
   - **Problem**: The official `nvcr.io/nvidia/clara-train-sdk:v4.1` has two critical issues:
     - GPU architecture whitelist rejects newer GPUs (container won't start)
     - CUDA driver compatibility issues (PyTorch can't detect GPU)
   - **Solution**: Ensure you selected "Clara Train SDK (v4.1)" from the ImageStream when creating the workbench
   - **Verify**: Check the workbench pod image:
     ```bash
     oc get pod <workbench-pod> -o jsonpath='{.spec.containers[0].image}'
     ```
     Should show the custom image from your registry (e.g., `quay.io/hacohen/clara-sdk:v4.1`), not `nvcr.io` directly

2. **GPU Not Requested**:
   - Verify GPU was requested in workbench creation (resource limits)
   - Review workbench pod spec: `oc describe pod <workbench-pod>`
   - Should show `nvidia.com/gpu: 1` in limits and requests

3. **GPU Operator Issues**:
   - Check GPU Operator status: `oc get pods -n nvidia-gpu-operator`
   - Verify all pods are Running

**Debug Steps**:
```bash
# Inside workbench terminal
nvidia-smi                    # Should show your GPU
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"  # Should be True

# If nvidia-smi works but PyTorch shows False:
# You're using the wrong image - recreate workbench with the ImageStream image
```

## Next Steps

After successful installation, follow the [Getting Started Guide](../getting_started.md) to:

1. Create your RHOAI workbench with the Clara Train SDK image
2. Clone the Clara Train examples repository
3. Run your first medical imaging AI training workflow

The getting started guide provides step-by-step instructions for running the GettingStarted notebook with GPU acceleration.

## Support

For issues specific to:
- **Clara Train SDK**: See [NVIDIA Clara Train documentation](https://docs.nvidia.com/clara/clara-train-sdk/)
- **RHOAI**: Consult Red Hat OpenShift AI documentation
- **This Installation**: Check [prerequisites.md](prerequisites.md) and run `make verify`

## License

This installation tooling follows the same license as the Clara Train examples repository.
