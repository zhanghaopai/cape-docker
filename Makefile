# Specify the shell environment for make
SHELL := /bin/bash

# Default target
all: docker-build

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	@docker build -t cape .

# Clean up binaries and temporary files
clean:
	@echo "Cleaning up..."
	@rm -rf $(BIN_DIR)

# Declare phony targets
.PHONY: all docker-build
