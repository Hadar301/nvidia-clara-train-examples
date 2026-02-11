# Clara Train Prerequisites

This directory contains the installation tooling for NVIDIA Clara Train SDK prerequisites on Red Hat OpenShift AI.

## Overview

This Helm chart and Makefile setup automates the deployment of:
- **NGC Registry Secret**: Authentication for NVIDIA container registry
- **Storage PVC**: Persistent volume for datasets and models (100GB)
- **ImageStream**: Clara Train SDK v4.1 container image for RHOAI workbenches

**Optional Component (not installed by default):**
- **Triton Inference Server**: For AI-Assisted Annotation (AIAA) functionality - requires model repository configuration

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
- Storage PVC (100GB)
- Clara Train ImageStream

**Note**: Triton Inference Server is **not** installed by default. See [Installing Triton Server](#installing-triton-server-optional) below if you need AIAA functionality.

### 4. Verify Installation

```bash
make verify
```

Wait for the ImageStream to import (~10-15 minutes for the 15GB image).

### 5. Create RHOAI Workbench

1. Navigate to RHOAI Dashboard
2. Create or select a Data Science Project
3. Create a new Workbench:
   - **Image**: Clara Train SDK (v4.1)
   - **GPU**: 1 nvidia.com/gpu
   - **CPU**: 16 cores
   - **Memory**: 64GB
   - **Storage**: 100GB
   - **Mount**: clara-train-storage PVC

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
| `make install-storage` | Install storage PVC only |
| `make install-triton` | Install Triton inference server only |
| `make install-imagestream` | Install Clara Train ImageStream only |
| `make verify` | Verify installation status |
| `make clean` | Remove all installed components |

## Directory Structure

```
clara-train-prerequisites/
├── Makefile                           # Installation orchestration
├── README.md                          # This file
├── prerequisites.md                   # Detailed prerequisites documentation
├── helm/
│   └── clara-train/
│       ├── Chart.yaml                 # Helm chart metadata
│       ├── values.yaml                # Configuration values
│       └── templates/
│           ├── _helpers.tpl           # Template helpers
│           ├── secret.yaml            # NGC registry secret
│           ├── pvc.yaml               # Storage PVC
│           ├── triton-deployment.yaml # Triton deployment
│           ├── triton-service.yaml    # Triton service
│           └── imagestream.yaml       # Clara Train ImageStream
└── scripts/
    ├── verify-installation.sh         # Post-install verification
    └── test-gpu.sh                    # GPU functionality test
```

## Customization

### Custom Storage Size

```bash
make install --set components.storage.size=200Gi
```

### Custom Storage Class

```bash
make install --set components.storage.storageClassName=my-storage-class
```

### Installing Triton Server (Optional)

Triton Inference Server is **not installed by default** because it requires:
1. A model repository to be configured (will crash without models)
2. Additional GPU resources (1 GPU dedicated to Triton)
3. AIAA-specific setup and configuration

**When do you need Triton?**
- Only if you plan to use AI-Assisted Annotation (AIAA) features
- AIAA enables interactive segmentation and annotation tools in medical imaging workflows
- Most Clara Train workflows (training, AutoML, federated learning) do **not** require Triton

**To install Triton:**

```bash
# Install Triton after setting up your AIAA models
make install-triton
```

**Important**: Before installing Triton, you must:
1. Create your RHOAI workbench with Clara Train SDK
2. Follow the AIAA setup instructions in `PyTorch/NoteBooks/AIAA/AIAA.ipynb`
3. Configure your model repository
4. Then install Triton using `make install-triton`

Otherwise, the Triton pod will crash with "no model repository" errors.

### Deploy ImageStream Cluster-Wide

```bash
make install --set components.imagestream.namespace=redhat-ods-applications
```

## Component Details

### NGC Registry Secret
- **Name**: `ngc-secret`
- **Type**: `kubernetes.io/dockerconfigjson`
- **Purpose**: Authenticate to NVIDIA Container Registry (nvcr.io)

### Storage PVC
- **Name**: `clara-train-storage`
- **Size**: 100Gi (configurable)
- **Access Mode**: ReadWriteOnce
- **Storage Class**: gp3-csi (configurable)

### Triton Inference Server (Optional - Not Installed by Default)
- **Name**: `triton-server`
- **Image**: `nvcr.io/nvidia/tritonserver:24.01-py3`
- **GPU**: 1 required
- **Ports**: 8000 (HTTP), 8001 (gRPC), 8002 (metrics)
- **Purpose**: AI-Assisted Annotation (AIAA) functionality
- **Installation**: Use `make install-triton` after configuring model repository
- **Requirements**:
  - Model repository must be configured first
  - GPU node with taints must be tolerated (configured in values.yaml)
  - Additional GPU resources available in cluster

### ImageStream
- **Name**: `clara-train-workbench`
- **Image**: `nvcr.io/nvidia/clara-train-sdk:v4.1`
- **Size**: ~15GB
- **Import Time**: 10-15 minutes
- **Purpose**: Notebook image for RHOAI workbenches

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

### PVC Pending
**Symptoms**: PVC created but status is Pending

**This is NORMAL**: Many storage classes (including gp3-csi) use `WaitForFirstConsumer` binding mode, which means the PVC won't bind until a pod actually uses it. The PVC will automatically bind when you create your workbench.

**To verify this is expected**:
```bash
# Check storage class binding mode
oc get sc gp3-csi -o jsonpath='{.volumeBindingMode}'
# Should output: WaitForFirstConsumer

# Check PVC status - "Pending" is normal
oc get pvc clara-train-storage -n <namespace>
```

**If PVC fails to bind when workbench is created**:
```bash
# Describe PVC for error events
oc describe pvc clara-train-storage -n <namespace>

# Check storage class exists
oc get sc

# Verify cluster has storage capacity
oc get pvc -A
```

### Triton Pod CrashLoop
**Symptoms**: Triton pod continuously restarting with "no model repository" errors

**Cause**: Triton requires a model repository to start. This is expected if you haven't configured AIAA models yet.

**Solution**:
1. **If you don't need AIAA**: Don't install Triton (it's optional)
2. **If you need AIAA**:
   - First, create your workbench and follow AIAA setup in notebooks
   - Configure your model repository
   - Then install Triton using `make install-triton`

**Debug commands** (if needed):
```bash
# Check pod logs
oc logs deployment/triton-server -n <namespace>

# Verify GPU availability
oc get nodes -l nvidia.com/gpu.present=true

# Check GPU node taints/tolerations
oc describe node <gpu-node-name>
```

### GPU Not Available in Workbench
**Symptoms**: `torch.cuda.is_available()` returns False

**Solution**:
- Verify GPU was requested in workbench creation (resource limits)
- Check GPU Operator status: `oc get pods -n nvidia-gpu-operator`
- Review workbench pod spec: `oc describe pod <workbench-pod>`

## Next Steps

After successful installation:

1. **Explore Examples**: Clone the official Clara Train examples
   ```bash
   git clone https://github.com/NVIDIA/clara-train-examples
   ```

2. **Start with Notebooks**:
   - `PyTorch/NoteBooks/Welcome.ipynb` - Overview
   - `PyTorch/NoteBooks/GettingStarted/GettingStarted.ipynb` - Basic workflow
   - `PyTorch/NoteBooks/Data/DownloadDecathlonDataSet.ipynb` - Sample datasets

3. **Try AIAA** (Optional - requires Triton): Interactive annotation with AI assistance
   - Follow setup in `PyTorch/NoteBooks/AIAA/AIAA.ipynb`
   - Then install Triton: `make install-triton`

4. **AutoML**: Automated hyperparameter optimization
   - `PyTorch/NoteBooks/AutoML/AutoML.ipynb`

## Support

For issues specific to:
- **Clara Train SDK**: See [NVIDIA Clara Train documentation](https://docs.nvidia.com/clara/clara-train-sdk/)
- **RHOAI**: Consult Red Hat OpenShift AI documentation
- **This Installation**: Check [prerequisites.md](prerequisites.md) and run `make verify`

## License

This installation tooling follows the same license as the Clara Train examples repository.
