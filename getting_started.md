# Getting Started with Clara Train on Red Hat OpenShift AI

This guide walks you through running your first Clara Train example on Red Hat OpenShift AI (RHOAI) with GPU acceleration.

## Prerequisites

- Red Hat OpenShift AI cluster with GPU support
- Clara Train prerequisites installed (see [clara-train-prerequisites/README.md](clara-train-prerequisites/README.md))
- NGC API key from https://ngc.nvidia.com/

## Step 1: Create a Workbench in RHOAI

1. **Access RHOAI Dashboard**
   - Navigate to your RHOAI dashboard URL
   - Log in with your OpenShift credentials

2. **Create or Select a Data Science Project**
   - Click on "Data Science Projects" in the left sidebar
   - Create a new project or select an existing one

3. **Create a Workbench**
   - Click "Create workbench"
   - Configure the workbench:
     - **Name**: `clara-workbench` (or any name you prefer)
     - **Notebook image**: Select **"Clara Train SDK (v4.1)"** from the dropdown
       - ⚠️ **IMPORTANT**: You must use the Clara Train SDK image from the ImageStream, NOT the official NVIDIA image
       - The custom image includes critical fixes for newer GPU architectures (L40S, Ada Lovelace, and newer)
     - **Container size**: Select a size appropriate for your needs
       - **Recommended**: Large or larger for medical imaging workloads
     - **Number of GPUs**: `1` (or more if available)
     - **Storage**:
       - Create new persistent storage or use existing
       - **Recommended size**: 100GB or more for datasets
   - Click "Create workbench"

4. **Wait for Workbench to Start**
   - Status will change from "Starting" to "Running"
   - This may take 1-2 minutes

5. **Open the Workbench**
   - Click the "Open" button next to your workbench
   - Jupyter Lab will open in a new tab

For detailed RHOAI documentation, see: [Getting Started with Red Hat OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service/1/html/getting_started_with_red_hat_openshift_ai_cloud_service/index)

## Step 2: Clone Clara Train Examples

You have two options to get the Clara Train examples:

### Option A: Using Terminal (Recommended)

In your workbench, open a terminal (File → New → Terminal) and run:

```bash
git clone https://github.com/NVIDIA/clara-train-examples.git
```

### Option B: Using RHOAI UI

1. In Jupyter Lab, click the Git icon in the left sidebar (or Git → Clone a Repository)
2. Enter the repository URL: `https://github.com/NVIDIA/clara-train-examples.git`
3. Click "Clone"
4. The repository will be cloned to your workspace

This will download all the Clara Train example notebooks and training configurations.

## Step 3: Configure the Environment

Edit the environment configuration file to set the data paths:

**File to edit**: `clara-train-examples/PyTorch/NoteBooks/GettingStarted/config/environment.json`

The default configuration has incorrect paths that need to be updated:

**Default (incorrect)**:
```json
{
    "DATA_ROOT": "/claraDevDay/Data/sampleData/",
    "DATASET_JSON": "/claraDevDay/Data/sampleData/dataset.json",
    ...
}
```

**Update to (correct)**:
```json
{
    "DATA_ROOT": "/opt/app-root/src/clara-train-examples/PyTorch/NoteBooks/Data/sampleData/",
    "DATASET_JSON": "/opt/app-root/src/clara-train-examples/PyTorch/NoteBooks/Data/sampleData/dataset.json",
    "PROCESSING_TASK": "segmentation",
    "MMAR_EVAL_OUTPUT_PATH": "eval",
    "MMAR_CKPT_DIR": "models",
    "MMAR_CKPT": "models/model.pt",
    "MMAR_TORCHSCRIPT": "models/model.ts"
}
```

⚠️ **IMPORTANT**: The `claraDevDay` path does not exist in the workbench. You must update the paths to point to the sample data in the cloned repository.

### Using Your Own Dataset

If you want to use a different dataset:

1. Update `DATA_ROOT` to point to your dataset directory
2. Update `DATASET_JSON` to point to your dataset JSON file
3. Ensure the dataset follows the Medical Segmentation Decathlon format

**Example with custom dataset**:
```json
{
    "DATA_ROOT": "/opt/app-root/src/datasets/Task07_Pancreas/",
    "DATASET_JSON": "/opt/app-root/src/datasets/Task07_Pancreas/dataset.json",
    ...
}
```

## Step 4: Open the Getting Started Notebook

In Jupyter Lab:

1. Navigate to: `clara-train-examples/PyTorch/NoteBooks/GettingStarted/`
2. Open: `GettingStarted.ipynb`
3. The notebook should open in Jupyter Lab

## Step 5: Run the Notebook

### Before You Start

**Verify GPU Access**:

Run this in a notebook cell to confirm your GPU is accessible:

```python
import torch
import monai

print(f"PyTorch: {torch.__version__}")
print(f"MONAI: {monai.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
```

Expected output:
```
PyTorch: 1.10.0a0+0aef44c
MONAI: 0.8.1
CUDA available: True
GPU: NVIDIA L40S
GPU Memory: 48.0 GB
```

### Running the Notebook

Work through the notebook cells sequentially:

1. **Setup cells** - Import libraries and load configuration
2. **Data exploration** - Visualize sample medical images
3. **Training** - Train a CNN for medical image segmentation
4. **Validation** - Evaluate model performance
5. **Inference** - Run predictions on test data

### Important: Single GPU vs Multi-GPU

**If you have only 1 GPU**, you should **skip the multi-GPU training sections**:

- ❌ Skip: Section 6.2 "Validate with multiple GPUs"
- ❌ Skip: Any cells that use `torch.nn.DataParallel` or multi-GPU configuration
- ✅ Run: All single GPU training and validation cells

The notebook includes both single-GPU and multi-GPU examples. The single-GPU sections will work perfectly on your workbench.

### Execution Tips

- **Run cells one at a time** to understand each step
- **Watch for errors** - if a cell fails, check the error message before continuing
- **Training time**: Initial training on sample data takes ~5-10 minutes on L40S GPU
- **Memory usage**: Monitor GPU memory in the notebook or via `nvidia-smi`

## What the Getting Started Notebook Covers

1. **Loading medical imaging data** - MONAI data loaders and transforms
2. **Data preprocessing** - Normalization, resizing, augmentation
3. **Model architecture** - UNet for medical image segmentation
4. **Training loop** - Single and multi-GPU training
5. **Validation** - Dice score and other medical imaging metrics
6. **Inference** - Running predictions on new data
7. **Visualization** - Plotting results and comparing predictions

## Troubleshooting

### GPU Not Detected

**Symptom**: `torch.cuda.is_available()` returns `False`

**Solution**:
1. Verify you're using the Clara Train SDK image from the ImageStream (not the official NVIDIA image)
2. Check pod image:
   ```bash
   oc get pod <workbench-pod> -o jsonpath='{.spec.containers[0].image}'
   ```
   Should show your custom image (e.g., `quay.io/hacohen/clara-sdk:v4.1`), not `nvcr.io/nvidia/clara-train-sdk:v4.1`
3. If using wrong image, recreate the workbench with the correct image

### Out of Memory Errors

**Symptom**: CUDA out of memory errors during training

**Solution**:
1. Reduce batch size in training configuration
2. Use smaller image patch sizes
3. Enable gradient checkpointing
4. Clear GPU cache: `torch.cuda.empty_cache()`

### Data Not Found Errors

**Symptom**: FileNotFoundError when loading data

**Solution**:
1. Verify paths in `environment.json` are correct and point to `/opt/app-root/src/clara-train-examples/PyTorch/NoteBooks/Data/sampleData/`
2. Check that data files exist: `ls -la /opt/app-root/src/clara-train-examples/PyTorch/NoteBooks/Data/sampleData/`
3. Ensure dataset JSON file is valid and matches the data directory structure

## Additional Resources

- **Clara Train SDK Documentation**: https://docs.nvidia.com/clara/clara-train-sdk/
- **Clara Train Examples Repository**: https://github.com/NVIDIA/clara-train-examples
- **MONAI Framework**: https://docs.monai.io/
- **Red Hat OpenShift AI**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service/1/
- **Medical Segmentation Decathlon**: http://medicaldecathlon.com/

## Support

For issues specific to:
- **Clara Train SDK**: Check NVIDIA Clara Train documentation and GitHub issues
- **RHOAI Setup**: See [clara-train-prerequisites/README.md](clara-train-prerequisites/README.md)
