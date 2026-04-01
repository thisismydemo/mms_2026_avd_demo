# FSLogix Configuration — AVD on Azure Local

## Overview

FSLogix is a **storage project**, not a profile project. The profile container (VHDx) is mounted at login and detached at logoff. Performance depends entirely on the underlying storage.

## Critical Registry Keys

All keys live under `HKLM\SOFTWARE\FSLogix\Profiles`:

| Key | Type | Value | Purpose |
|-----|------|-------|---------|
| `Enabled` | DWORD | `1` | Enable FSLogix profile containers |
| `VHDLocations` | String | `\\fileserver\profiles` | UNC path to SMB share |
| `SizeInMBs` | DWORD | `15000` | Max VHDx size (~15 GB) |
| `IsDynamic` | DWORD | `1` | Use dynamic VHDx (grows on demand) |
| `DeleteLocalProfileWhenVHDShouldApply` | DWORD | `1` | Prevent local profile copies |
| `FlipFlopProfileDirectoryName` | DWORD | `1` | Use `username_SID` instead of `SID_username` |
| `VolumeType` | String | `VHDX` | Use VHDX format (not VHD) |

## Redirections.xml

Exclude high-churn, low-value data from the profile container:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FrxProfileFolderRedirection ExcludeCommonFolders="0">
  <Excludes>
    <Exclude Copy="0">AppData\Local\Microsoft\Teams</Exclude>
    <Exclude Copy="0">AppData\Local\Google\Chrome\User Data\Default\Cache</Exclude>
    <Exclude Copy="0">AppData\Local\Microsoft\Edge\User Data\Default\Cache</Exclude>
    <Exclude Copy="0">AppData\Local\Temp</Exclude>
    <Exclude Copy="0">AppData\Local\Microsoft\Windows\INetCache</Exclude>
    <Exclude Copy="0">AppData\Local\Microsoft\OneDrive\logs</Exclude>
  </Excludes>
</FrxProfileFolderRedirection>
```

Deploy via GPO or place in `C:\Program Files\FSLogix\Apps\Rules\`.

## Storage Sizing

**Login storm math:**
- 200 users × 50 IOPS average = **10,000 IOPS peak** during login window
- Each VHDx at 15 GB max → plan for **3 TB** total capacity (200 × 15 GB)
- Add 20% headroom for growth

**Storage options on Azure Local:**
- Local CSV (cluster shared volume) — highest IOPS, no network hop
- SMB file server on separate hardware — more capacity, network-dependent
- Scale-Out File Server (SOFS) — HA, distributed, recommended for production

## Profile Compaction

VHDx files grow but never automatically shrink. Regular compaction reclaims whitespace.

```powershell
# Using FSLogix's built-in tool
Invoke-FslShrinkDisk -Path "\\fileserver\profiles" `
    -Recurse `
    -PassThru `
    -MinimumWhiteSpace 20
```

Schedule weekly or monthly during maintenance windows.

## High Availability Options

| Option | Recommendation | Notes |
|--------|---------------|-------|
| Scale-Out File Server (SOFS) | Recommended | Built-in HA on Windows Server |
| Cloud Cache | Use for DR | Writes to local cache, replicates to multiple targets |
| DFS-R | **Do not use** | Not supported for live VHDx replication |
