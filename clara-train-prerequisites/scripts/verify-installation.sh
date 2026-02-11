#!/bin/bash

# Clara Train Prerequisites Verification Script
# Cluster-agnostic verification of installed components

set -e

NAMESPACE="${1:-}"

if [ -z "$NAMESPACE" ]; then
    echo "ERROR: Namespace parameter required"
    echo "Usage: $0 <namespace>"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Clara Train Prerequisites Verification"
echo "  Namespace: $NAMESPACE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track overall status
FAILED=0

# Check NGC Secret
echo "Checking NGC Registry Secret..."
if oc get secret ngc-secret -n "$NAMESPACE" &>/dev/null; then
    echo "  ✓ NGC secret exists"
else
    echo "  ✗ NGC secret NOT FOUND"
    FAILED=1
fi
echo ""

# Check PVC
echo "Checking Persistent Volume Claim..."
if oc get pvc clara-train-storage -n "$NAMESPACE" &>/dev/null; then
    PVC_STATUS=$(oc get pvc clara-train-storage -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$PVC_STATUS" == "Bound" ]; then
        PVC_SIZE=$(oc get pvc clara-train-storage -n "$NAMESPACE" -o jsonpath='{.status.capacity.storage}')
        echo "  ✓ PVC exists and is Bound ($PVC_SIZE)"
    elif [ "$PVC_STATUS" == "Pending" ]; then
        # Check if this is WaitForFirstConsumer (expected)
        BINDING_MODE=$(oc get sc gp3-csi -o jsonpath='{.volumeBindingMode}' 2>/dev/null || echo "Unknown")
        if [ "$BINDING_MODE" == "WaitForFirstConsumer" ]; then
            echo "  ✓ PVC exists (Pending - waiting for workbench to be created)"
            echo "    This is normal with WaitForFirstConsumer storage class"
        else
            echo "  ⚠ PVC exists but status is: $PVC_STATUS"
            FAILED=1
        fi
    else
        echo "  ⚠ PVC exists but status is: $PVC_STATUS"
        FAILED=1
    fi
else
    echo "  ✗ PVC NOT FOUND"
    FAILED=1
fi
echo ""

# Check Triton Deployment
echo "Checking Triton Inference Server..."
if oc get deployment triton-server -n "$NAMESPACE" &>/dev/null; then
    TRITON_READY=$(oc get deployment triton-server -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    TRITON_DESIRED=$(oc get deployment triton-server -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$TRITON_READY" == "$TRITON_DESIRED" ] && [ -n "$TRITON_READY" ]; then
        echo "  ✓ Triton deployment is ready ($TRITON_READY/$TRITON_DESIRED replicas)"
    else
        echo "  ⚠ Triton deployment exists but not ready ($TRITON_READY/$TRITON_DESIRED replicas)"

        # Check pod status for more details
        POD_STATUS=$(oc get pods -n "$NAMESPACE" -l app=triton-server -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
        echo "    Pod status: $POD_STATUS"

        if [ "$POD_STATUS" == "Pending" ]; then
            echo "    Tip: Check if GPU resources are available"
        fi
        FAILED=1
    fi
else
    echo "  ⚠ Triton deployment not installed (optional component)"
fi
echo ""

# Check Triton Service
echo "Checking Triton Service..."
if oc get service triton-server-service -n "$NAMESPACE" &>/dev/null; then
    CLUSTER_IP=$(oc get service triton-server-service -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
    echo "  ✓ Triton service exists (ClusterIP: $CLUSTER_IP)"
else
    echo "  ⚠ Triton service not found (expected if Triton deployment is disabled)"
fi
echo ""

# Check ImageStream
echo "Checking Clara Train ImageStream..."
if oc get imagestream clara-train-workbench -n "$NAMESPACE" &>/dev/null; then
    # Check if image has been imported
    IMAGE_TAGS=$(oc get imagestream clara-train-workbench -n "$NAMESPACE" -o jsonpath='{.status.tags[*].tag}' 2>/dev/null || echo "")

    if [ -n "$IMAGE_TAGS" ]; then
        echo "  ✓ ImageStream exists with imported tags: $IMAGE_TAGS"

        # Check the Docker image reference
        IMAGE_REF=$(oc get imagestream clara-train-workbench -n "$NAMESPACE" -o jsonpath='{.status.tags[0].items[0].dockerImageReference}' 2>/dev/null || echo "Not available")
        echo "    Image: $IMAGE_REF"
    else
        echo "  ⚠ ImageStream exists but no tags imported yet"
        echo "    This is normal for the first 10-15 minutes after installation"
        echo "    Tip: Check import status with: oc describe imagestream clara-train-workbench -n $NAMESPACE"
        FAILED=1
    fi
else
    echo "  ✗ ImageStream NOT FOUND"
    FAILED=1
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo "  ✓ All core components verified successfully"
    echo ""
    echo "Ready to create RHOAI Workbench!"
    echo ""
    echo "Next steps:"
    echo "  1. Navigate to RHOAI Dashboard"
    echo "  2. Create a new Data Science Project (or use existing)"
    echo "  3. Create a Workbench:"
    echo "     - Image: Clara Train SDK (v4.1)"
    echo "     - GPU: 1 nvidia.com/gpu"
    echo "     - CPU: 16 cores"
    echo "     - Memory: 64GB RAM"
    echo "     - Storage: Mount clara-train-storage PVC"
    echo "  4. The PVC will bind automatically when workbench starts"
else
    echo "  ⚠ Some components are not ready or missing"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check Helm release: helm list -n $NAMESPACE"
    echo "  - View pod logs: oc logs -n $NAMESPACE <pod-name>"
    echo "  - Check events: oc get events -n $NAMESPACE --sort-by='.lastTimestamp'"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit $FAILED
