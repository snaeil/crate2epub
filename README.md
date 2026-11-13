# crate2epub

This script makes it easy to build a crate's documentation into epub.

## Prerequisites

You must have installed:

- pandoc
- cargo
- curl (optional, needed if you don't want to download this repo)

## Usage

```bash
curl -s https://raw.githubusercontent.com/snaeil/crate2epub/refs/heads/main/crate2epub.sh | bash  <crate-name> [version]
```

Example:

```bash
curl -s https://raw.githubusercontent.com/snaeil/crate2epub/refs/heads/main/crate2epub.sh | bash axum 0.8.9
```

