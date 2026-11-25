# RapStuff Auto Sync Script

Interactive Bash script to clone device, vendor, kernel, and hardware repositories for RapStuff custom ROM builds from your Android ROM source root directory.

## Supported devices

- `sweet`: Xiaomi Redmi Note 10 Pro
- `xun`: Xiaomi Redmi Pad SE
- `kj7`: TECNO Spark 20 Pro+

## How to use

Run from the root of your Android ROM source tree without cloning this repository.

Pick a device interactively:

```bash
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sync.sh | bash
```

Or target a device directly:

```bash
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sync.sh | bash -s -- sweet
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sync.sh | bash -s -- xun
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sync.sh | bash -s -- kj7
```

The legacy `sweet.sh` and `xun.sh` wrappers still work:

```bash
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sweet.sh | bash
curl -sL https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/xun.sh | bash
```
