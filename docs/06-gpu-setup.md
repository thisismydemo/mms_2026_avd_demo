# GPU Setup — AVD on Azure Local

## Overview

Azure Local supports GPU acceleration for AVD session hosts using two methods:

| Method | Use Case | Density | Isolation |
|--------|----------|---------|-----------|
| **DDA** (Discrete Device Assignment) | Dedicated GPU per VM | 1:1 | Full |
| **GPU-P** (GPU Partitioning) | Shared GPU across VMs | Many:1 | Partitioned |

For multi-session AVD, **GPU-P is recommended** for density.

## GPU-P Setup Flow

### 1. Install Host Driver

Install the NVIDIA driver on the Azure Local cluster node. The driver must support SR-IOV / GPU partitioning.

### 2. Partition the GPU

```powershell
# View available GPUs on the host
Get-VMHostPartitionableGpu

# Set partition count (example: 8 partitions)
Set-VMHostPartitionableGpu -Name "GPU-name" -PartitionCount 8
```

### 3. Attach Partition to VM

Assign a GPU partition to each AVD session host VM that needs GPU acceleration.

### 4. Install Guest Driver

Install the NVIDIA vGPU guest driver inside the VM. **The guest driver version must be compatible with the host driver version.** Mismatches cause the vGPU to fail to load.

### 5. Configure NVIDIA Licensing

Configure either:
- **CLS** (Cloud License Server) — hosted by NVIDIA
- **DLS** (Delegated License Server) — self-hosted

## Verification

On the cluster node:
```powershell
Get-VMHostPartitionableGpu
```

Inside the session host VM:
```cmd
nvidia-smi
```

Expected output shows: GPU model, driver version, memory allocation, utilization.

## RDP Graphics Policies

Configure via GPO or local policy on session hosts:

| Policy | Setting | Path |
|--------|---------|------|
| Use hardware graphics adapters for all RDP sessions | Enabled | Computer Config → Admin Templates → Windows Components → Remote Desktop Services → Remote Desktop Session Host → Remote Session Environment |
| Configure H.264/AVC hardware encoding | Enabled | Same path |
| Prioritize H.265/HEVC graphics mode | Enabled | Same path |
| Configure image quality for RemoteFX Adaptive Graphics | High | Same path |

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| nvidia-smi not found | Guest driver not installed | Install NVIDIA vGPU guest driver |
| nvidia-smi shows no GPU | Partition not attached | Verify GPU partition assignment to VM |
| GPU driver error | Version mismatch | Match guest driver version to host driver |
| Poor rendering performance | RDP policies not set | Apply graphics policies above |
