# NVIDIA Clara Train Examples on Red Hat OpenShift AI

This repository contains the setup and configuration for running [NVIDIA Clara Train SDK](https://github.com/NVIDIA/clara-train-examples) on Red Hat OpenShift AI (RHOAI) with GPU acceleration.

## Overview

NVIDIA Clara Train SDK is a framework for training deep learning models on medical imaging data. This repository provides the necessary infrastructure to deploy Clara Train on OpenShift AI with support for modern GPU architectures.

## What This Repository Provides

### Custom Clara Train Image

The official `nvcr.io/nvidia/clara-train-sdk:v4.1` container has compatibility issues with newer GPU architectures (Ada Lovelace, Hopper, and later) and modern CUDA drivers. This repository includes:

- **Custom Containerfile** with GPU compatibility fixes for newer architectures
- **CUDA driver compatibility** fixes for driver versions 580.x+
- **RHOAI integration** with proper Jupyter configuration

**Key fixes applied**:
1. Bypasses GPU architecture whitelist that rejects newer GPUs (L40S, L40, H100, etc.)
2. Removes outdated CUDA compat libraries that conflict with modern drivers
3. Configures Jupyter for multi-tenant RHOAI environment with token authentication

See [clara-train-prerequisites/Containerfile](clara-train-prerequisites/Containerfile) for implementation details.

### Automated Installation

Helm charts and Makefile automation for deploying:
- **NGC Registry Secret**: Authentication for NVIDIA Container Registry
- **ImageStream**: Custom Clara Train image available in RHOAI notebook selector

See [clara-train-prerequisites/](clara-train-prerequisites/) for installation instructions.

### Documentation

- **[Prerequisites README](clara-train-prerequisites/README.md)**: Installation and troubleshooting guide
- **[Getting Started Guide](getting_started.md)**: Step-by-step instructions for running your first Clara Train notebook

## Quick Start

### 1. Install Prerequisites

Install the Clara Train prerequisites in your OpenShift cluster:

```bash
cd clara-train-prerequisites
make install
```

This will:
- Create NGC registry secret for pulling NVIDIA images
- Deploy the custom Clara Train ImageStream to RHOAI
- Make the image available in the RHOAI workbench selector

See [clara-train-prerequisites/README.md](clara-train-prerequisites/README.md) for detailed installation instructions.

### 2. Create RHOAI Workbench

1. Access your RHOAI dashboard
2. Create or select a Data Science Project
3. Create a new workbench:
   - **Image**: Select "Clara Train SDK (v4.1)" from the dropdown
   - **GPU**: 1 nvidia.com/gpu (or more if available)
   - **Memory**: 64GB recommended
   - **Storage**: 100GB+ recommended for datasets

**Important**: You must use the custom Clara Train SDK image from the ImageStream, not the official NVIDIA image directly.

### 3. Run Getting Started Notebook

Follow the [Getting Started Guide](getting_started.md) for step-by-step instructions on:
- Cloning the Clara Train examples repository
- Configuring environment paths
- Running your first medical imaging AI training

## Why a Custom Image is Required

The official Clara Train SDK v4.1 (released October 2021) has two critical incompatibilities with modern GPU infrastructure:

### Problem 1: GPU Architecture Compatibility
- Clara Train v4.1 only recognizes Ampere GPUs and older
- Newer architectures (Ada Lovelace: L40S/L40, Hopper: H100, etc.) are rejected
- Container fails to start with: `ERROR: No supported GPU(s) detected`

### Problem 2: CUDA Driver Compatibility
- Base image contains CUDA compat libraries for driver 470.x
- Modern clusters run driver 580.x+
- Results in `torch.cuda.is_available()` returning `False` despite GPU being present

### Our Solution
The custom [Containerfile](clara-train-prerequisites/Containerfile) fixes both issues by:
1. Bypassing the GPU architecture validation
2. Removing outdated compat libraries and using host driver libraries
3. Adding RHOAI-specific Jupyter configuration

## Repository Structure

```
.
├── README.md                          # This file
├── getting_started.md                 # Quick start guide for running notebooks
├── clara-train-prerequisites/         # Installation automation
│   ├── README.md                      # Installation and troubleshooting
│   ├── Containerfile                  # Custom image with GPU fixes
│   ├── Makefile                       # Installation automation
│   ├── prerequisites.md               # Cluster requirements
│   └── helm/                          # Helm charts for deployment
│       └── clara-train/
│           ├── values.yaml            # Configuration values
│           └── templates/             # Kubernetes manifests

```
