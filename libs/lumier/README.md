<div align="center">
<h1>
  <div class="image-wrapper" style="display: inline-block;">
    <picture>
      <source media="(prefers-color-scheme: dark)" alt="logo" height="150" srcset="../../img/logo_white.png" style="display: block; margin: auto;">
      <source media="(prefers-color-scheme: light)" alt="logo" height="150" srcset="../../img/logo_black.png" style="display: block; margin: auto;">
      <img alt="Shows my svg">
    </picture>
  </div>

  [![Swift 6](https://img.shields.io/badge/Swift_6-F54A2A?logo=swift&logoColor=white&labelColor=F54A2A)](#)
  [![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=F0F0F0)](#)
  [![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?logo=homebrew&logoColor=fff)](#install)
  [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?&logo=discord&logoColor=white)](https://discord.com/invite/mVnXXpdE85)
</h1>
</div>

macOS and Linux virtual machines in a Docker container.

## What is Lumier?
**Lumier** is an interface for running macOS virtual machines with minimal setup. It uses Docker as a packaging system to deliver a pre-configured environment that connects to the `lume` virtualization service running on your host machine. With Lumier, you get:

- A ready-to-use macOS or Linux virtual machine in minutes
- Browser-based VNC access to your VM
- Easy file sharing between your host and VM
- Simple configuration through environment variables

## Requirements

Before using Lumier, make sure you have:

1. **Docker for Apple Silicon** - download it [here](https://desktop.docker.com/mac/main/arm64/Docker.dmg) and follow the installation instructions.

2. **Lume** - This is the virtualization CLI that powers Lumier. Install it with this command:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
```

After installation, Lume runs as a background service and listens on port 3000. This service allows Lumier to create and manage virtual machines. If port 3000 is already in use on your system, you can specify a different port with the `--port` option when running the `install.sh` script.

## How It Works

> **Note:** We're using Docker primarily as a convenient delivery mechanism, not as an isolation layer. Unlike traditional Docker containers, Lumier leverages the Apple Virtualization Framework (Apple Vz) through the `lume` CLI to create true virtual machines.

Here's what's happening behind the scenes:

1. The Docker container provides a consistent environment to run the Lumier interface
2. Lumier connects to the Lume service running on your host Mac
3. Lume uses Apple's Virtualization Framework to create a true macOS virtual machine
4. The VM runs with hardware acceleration using your Mac's native virtualization capabilities

## Getting Started

```bash
# 1. Navigate to the Lumier directory
cd libs/lumier

# 2. Run the container with temporary storage (using pre-built image from Docker Hub)
docker run -it --rm \
    --name lumier-vm \
    -p 8006:8006 \
    -e VM_NAME=lumier-vm \
    -e VERSION=ghcr.io/trycua/macos-sequoia-cua:latest \
    -e CPU_CORES=4 \
    -e RAM_SIZE=8192 \
    trycua/lumier:latest
```

After running the command above, you can access your macOS VM through a web browser (e.g., http://localhost:8006).

> **Note:** With the basic setup above, your VM will be reset when you stop the container (ephemeral mode). This means any changes you make inside the macOS VM will be lost. See the section below for how to save your VM state.

## Saving Your VM State

To save your VM state between sessions (so your changes persist when you stop and restart the container), you'll need to set up a storage location:

```bash
# First, create a storage directory if it doesn't exist
mkdir -p storage

# Then run the container with persistent storage
docker run -it --rm \
    --name lumier-vm \
    -p 8006:8006 \
    -v $(pwd)/storage:/storage \
    -e VM_NAME=lumier-vm \
    -e VERSION=ghcr.io/trycua/macos-sequoia-cua:latest \
    -e CPU_CORES=4 \
    -e RAM_SIZE=8192 \
    -e HOST_STORAGE_PATH=$(pwd)/storage \
    trycua/lumier:latest
```

This command creates a connection between a folder on your Mac (`$(pwd)/storage`) and a folder inside the Docker container (`/storage`). The `-v` flag (volume mount) and the `HOST_STORAGE_PATH` variable work together to ensure your VM data is saved on your host Mac.

## Sharing Files with Your VM

To share files between your Mac and the virtual machine, you can set up a shared folder:

```bash
# Create both storage and shared folders
mkdir -p storage shared

# Run with both persistent storage and a shared folder
docker run -it --rm \
    --name lumier-vm \
    -p 8006:8006 \
    -v $(pwd)/storage:/storage \
    -v $(pwd)/shared:/shared \
    -e VM_NAME=lumier-vm \
    -e VERSION=ghcr.io/trycua/macos-sequoia-cua:latest \
    -e CPU_CORES=4 \
    -e RAM_SIZE=8192 \
    -e HOST_STORAGE_PATH=$(pwd)/storage \
    -e HOST_SHARED_PATH=$(pwd)/shared \
    trycua/lumier:latest
```

With this setup, any files you place in the `shared` folder on your Mac will be accessible from within the macOS VM, and vice versa.

## Automating VM Startup with on-logon.sh

You can automatically run scripts when the VM starts up by placing an `on-logon.sh` script in the shared folder's lifecycle directory. This is useful for setting up your VM environment each time it starts.

```bash
# Create the lifecycle directory in your shared folder
mkdir -p shared/lifecycle

# Create a sample on-logon.sh script
cat > shared/lifecycle/on-logon.sh << 'EOF'
#!/usr/bin/env bash

# Create a file on the desktop
echo "Hello from Lumier!" > /Users/lume/Desktop/hello_lume.txt

# You can add more commands to execute at VM startup
# For example:
# - Configure environment variables
# - Start applications
# - Mount network drives
# - Set up development environments
EOF

# Make the script executable
chmod +x shared/lifecycle/on-logon.sh
```

The script will be automatically executed when the VM starts up. It runs in the VM context and has access to:

- The `/Users/lume` user directory (home directory in the VM)
- The shared folder at `/Volumes/My Shared Files` inside the VM
- Any resources available to the VM

This feature enables automation of VM setup without modifying the base VM image.

## Using Docker Compose

You can also use Docker Compose to run Lumier with a simple configuration file. Create a `docker-compose.yml` file with the following content:

```yaml
version: '3'

services:
  lumier:
    image: trycua/lumier:latest
    container_name: lumier-vm
    restart: unless-stopped
    ports:
      - "8006:8006"  # Port for VNC access
    volumes:
      - ./storage:/storage  # VM persistent storage
      - ./shared:/shared    # Shared folder accessible in the VM
    environment:
      - VM_NAME=lumier-vm
      - VERSION=ghcr.io/trycua/macos-sequoia-cua:latest
      - CPU_CORES=4
      - RAM_SIZE=8192
      - HOST_STORAGE_PATH=${PWD}/storage
      - HOST_SHARED_PATH=${PWD}/shared
    stop_signal: SIGINT
    stop_grace_period: 2m
```

Then run Lumier using:

```bash
# First create the required directories
mkdir -p storage shared

# Start the container
docker-compose up -d

# View the logs
docker-compose logs -f

# Stop the container when done
docker-compose down
```

## Building and Customizing Lumier

If you want to customize the Lumier container or build it from source, you can follow these steps:

```bash
# 1. Navigate to the Lumier directory
cd libs/lumier

# 2. Build the Docker image locally
docker build -t lumier-custom:latest .

# 3. Run your custom build
docker run -it --rm \
    --name lumier-vm \
    -p 8006:8006 \
    -e VM_NAME=lumier-vm \
    -e VERSION=ghcr.io/trycua/macos-sequoia-cua:latest \
    -e CPU_CORES=4 \
    -e RAM_SIZE=8192 \
    lumier-custom:latest
```

### Customization Options

The Dockerfile provides several customization points:

1. **Base image**: The container uses Debian Bullseye Slim as the base. You can modify this if needed.
2. **Installed packages**: You can add or remove packages in the apt-get install list.
3. **Hooks**: Check the `/run/hooks/` directory for scripts that run at specific points during VM lifecycle.
4. **Configuration**: Review `/run/config/constants.sh` for default settings.

After making your modifications, you can build and push your custom image to your own Docker Hub repository:

```bash
# Build with a custom tag
docker build -t yourusername/lumier:custom .

# Push to Docker Hub (after docker login)
docker push yourusername/lumier:custom
```

## Configuration Options

When running Lumier, you'll need to configure a few things:

- **Port forwarding** (`-p 8006:8006`): Makes the VM's VNC interface accessible in your browser. If port 8006 is already in use, you can use a different port like `-p 8007:8006`.

- **Environment variables** (`-e`): Configure your VM settings:
  - `VM_NAME`: A name for your virtual machine
  - `VERSION`: The macOS image to use
  - `CPU_CORES`: Number of CPU cores to allocate
  - `RAM_SIZE`: Memory in MB to allocate
  - `HOST_STORAGE_PATH`: Path to save VM state (when using persistent storage)
  - `HOST_SHARED_PATH`: Path to the shared folder (optional)

- **Background service**: The `lume serve` service should be running on your host (starts automatically when you install Lume using the `install.sh` script above).

## Credits

This project was inspired by [dockur/windows](https://github.com/dockur/windows) and [dockur/macos](https://github.com/dockur/macos), which pioneered the approach of running Windows and macOS VMs in Docker containers.

Main differences with dockur/macos:
- Lumier is specifically designed for macOS virtualization
- Lumier supports Apple Silicon (M1/M2/M3/M4) while dockur/macos only supports Intel
- Lumier uses the Apple Virtualization Framework (Vz) through the `lume` CLI to create true virtual machines, while dockur relies on KVM.
- Image specification is different, with Lumier and Lume relying on Apple Vz spec (disk.img and nvram.bin)