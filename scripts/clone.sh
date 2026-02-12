#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo $SCRIPT_DIR
cd $PROJECT_ROOT

echo "Cloning NeMo Microservices..."
git clone https://github.com/NVIDIA/clara-train-examples.git

echo "Done Cloning!"