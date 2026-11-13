# crate2epub

This script makes it easy to build a crate's documentation into epub.

## Prerequisites

You must have installed:

- pandoc
- cargo
- curl (optional, needed if you don't want to download this repo)

## Usage

With downloading script `crate2epub.sh`:

```bash
./crate2epub.sh <crate-name> [version]
```

Without downloading script (needs curl):

```bash
curl -s https://raw.githubusercontent.com/snaeil/crate2epub/refs/heads/main/crate2epub.sh | bash -s -- <crate-name> [version]
```

You will then find the created `epub` with name `` at the current directory.

Example:

```bash
curl -s https://raw.githubusercontent.com/snaeil/crate2epub/refs/heads/main/crate2epub.sh | bash -s -- axum 0.8.9
```

