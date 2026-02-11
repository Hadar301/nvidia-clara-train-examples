#!/bin/bash

# Clara Train GPU Test Script
# Generic GPU verification for any NVIDIA GPU (cluster-agnostic)
# Run this script inside a Clara Train workbench notebook terminal

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Clara Train GPU Functionality Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track overall status
FAILED=0

# Test 1: Check nvidia-smi
echo "Test 1: Checking NVIDIA Driver..."
if command -v nvidia-smi &>/dev/null; then
    echo "  ✓ nvidia-smi is available"
    echo ""
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader | while IFS=, read -r name memory driver; do
        echo "    GPU: $name"
        echo "    Memory: $memory"
        echo "    Driver: $driver"
    done
    echo ""
else
    echo "  ✗ nvidia-smi not found"
    FAILED=1
fi

# Test 2: PyTorch CUDA Test
echo "Test 2: Checking PyTorch CUDA Support..."
python3 << 'EOF'
import sys
try:
    import torch
    print(f"  ✓ PyTorch version: {torch.__version__}")

    if torch.cuda.is_available():
        print(f"  ✓ CUDA available: True")
        print(f"  ✓ CUDA version: {torch.version.cuda}")
        print(f"  ✓ GPU count: {torch.cuda.device_count()}")

        for i in range(torch.cuda.device_count()):
            gpu_name = torch.cuda.get_device_name(i)
            gpu_memory = torch.cuda.get_device_properties(i).total_memory / (1024**3)
            print(f"  ✓ GPU {i}: {gpu_name} ({gpu_memory:.1f}GB)")
    else:
        print("  ✗ CUDA not available in PyTorch")
        sys.exit(1)
except ImportError as e:
    print(f"  ✗ PyTorch not installed: {e}")
    sys.exit(1)
except Exception as e:
    print(f"  ✗ Error checking PyTorch CUDA: {e}")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    FAILED=1
fi
echo ""

# Test 3: MONAI Import Test
echo "Test 3: Checking MONAI Framework..."
python3 << 'EOF'
import sys
try:
    import monai
    print(f"  ✓ MONAI version: {monai.__version__}")

    # Check MONAI config
    from monai.config import print_config
    import io
    import contextlib

    # Capture print_config output
    f = io.StringIO()
    with contextlib.redirect_stdout(f):
        print_config()

    config_output = f.getvalue()

    # Extract key information
    if "CUDA" in config_output:
        print("  ✓ MONAI CUDA support detected")

    print("  ✓ MONAI successfully imported")

except ImportError as e:
    print(f"  ⚠ MONAI not installed: {e}")
    print("    This is expected if using base Clara Train image")
except Exception as e:
    print(f"  ✗ Error checking MONAI: {e}")
    sys.exit(1)
EOF

# Note: Don't fail if MONAI is not found (might be optional)
echo ""

# Test 4: Simple CUDA Tensor Operation
echo "Test 4: Testing GPU Tensor Operations..."
python3 << 'EOF'
import sys
try:
    import torch

    # Create tensor on GPU
    device = torch.device("cuda:0")
    x = torch.randn(1000, 1000, device=device)
    y = torch.randn(1000, 1000, device=device)

    # Perform operation
    z = torch.mm(x, y)

    # Verify result is on GPU
    if z.is_cuda:
        print("  ✓ GPU tensor operations successful")
        print(f"    Matrix multiplication: 1000x1000 @ 1000x1000")
        print(f"    Result tensor shape: {z.shape}")
        print(f"    Result device: {z.device}")
    else:
        print("  ✗ Tensor operation did not use GPU")
        sys.exit(1)

except Exception as e:
    print(f"  ✗ GPU tensor operation failed: {e}")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    FAILED=1
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo "  ✓ All GPU tests passed successfully"
    echo ""
    echo "Your Clara Train environment is ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Clone Clara Train examples: git clone https://github.com/NVIDIA/clara-train-examples"
    echo "  2. Navigate to PyTorch/NoteBooks/"
    echo "  3. Start with Welcome.ipynb"
    echo "  4. Follow GettingStarted/GettingStarted.ipynb"
else
    echo "  ✗ Some GPU tests failed"
    echo ""
    echo "Troubleshooting:"
    echo "  - Verify GPU is allocated to the workbench (check resource limits)"
    echo "  - Check GPU Operator status in the cluster"
    echo "  - Review workbench pod logs for GPU allocation errors"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit $FAILED
