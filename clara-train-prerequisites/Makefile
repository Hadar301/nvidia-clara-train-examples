.PHONY: help install install-secret install-storage install-triton install-imagestream verify clean

# Load environment variables from .env file
include ../.env
export

# Helm variables
HELM_RELEASE := clara-train
HELM_CHART := ./helm/clara-train

help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Clara Train Prerequisites - Installation Commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Available targets:"
	@echo "  make install            - Install all prerequisites"
	@echo "  make install-secret     - Install NGC registry secret only"
	@echo "  make install-storage    - Install storage PVC only"
	@echo "  make install-triton     - Install Triton inference server only"
	@echo "  make install-imagestream - Install Clara Train ImageStream only"
	@echo "  make verify             - Verify installation"
	@echo "  make clean              - Remove all installed components"
	@echo ""
	@echo "Environment Configuration:"
	@echo "  NAMESPACE:   $(NAMESPACE)"
	@echo "  NGC_API_KEY: $(if $(NGC_API_KEY),✓ configured,✗ NOT SET)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

install:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing Clara Train Prerequisites"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ -z "$(NGC_API_KEY)" ]; then \
		echo "ERROR: NGC_API_KEY is not set in .env file"; \
		exit 1; \
	fi
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "ERROR: NAMESPACE is not set in .env file"; \
		exit 1; \
	fi
	@helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set ngcApiKey=$(NGC_API_KEY) \
		--set namespace=$(NAMESPACE) \
		 
	@echo ""
	@echo "✓ Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run 'make verify' to check installation status"
	@echo "  2. Wait for ImageStream import to complete (~10-15 minutes)"
	@echo "  3. Create RHOAI Workbench using Clara Train SDK image"
	@echo ""

install-secret:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing NGC Registry Secret"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ -z "$(NGC_API_KEY)" ]; then \
		echo "ERROR: NGC_API_KEY is not set in .env file"; \
		exit 1; \
	fi
	@helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set ngcApiKey=$(NGC_API_KEY) \
		--set namespace=$(NAMESPACE) \
		--set components.secret.enabled=true \
		--set components.storage.enabled=false \
		--set components.triton.enabled=false \
		--set components.imagestream.enabled=false \
		> /dev/null 2>&1
	@echo "✓ NGC secret installed"

install-storage:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing Storage PVC"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set namespace=$(NAMESPACE) \
		--set components.secret.enabled=false \
		--set components.storage.enabled=true \
		--set components.triton.enabled=false \
		--set components.imagestream.enabled=false \
		> /dev/null 2>&1
	@echo "✓ Storage PVC installed"

install-triton:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing Triton Inference Server"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set namespace=$(NAMESPACE) \
		--set components.secret.enabled=false \
		--set components.storage.enabled=false \
		--set components.triton.enabled=true \
		--set components.imagestream.enabled=false \
		> /dev/null 2>&1
	@echo "✓ Triton server installed"

install-imagestream:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing Clara Train ImageStream"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set namespace=$(NAMESPACE) \
		--set components.secret.enabled=false \
		--set components.storage.enabled=false \
		--set components.triton.enabled=false \
		--set components.imagestream.enabled=true \
		> /dev/null 2>&1
	@echo "✓ ImageStream installed"
	@echo ""
	@echo "Note: Image import may take 10-15 minutes (~15GB download)"
	@echo "Check status: oc get imagestream clara-train-workbench -n $(NAMESPACE)"

verify:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Verifying Clara Train Installation"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@bash scripts/verify-installation.sh $(NAMESPACE)

clean:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Removing Clara Train Prerequisites"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "WARNING: This will remove all Clara Train components from namespace: $(NAMESPACE)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		helm uninstall $(HELM_RELEASE) --namespace $(NAMESPACE) || true; \
		echo "✓ Cleanup complete"; \
	else \
		echo "Cleanup cancelled"; \
	fi
