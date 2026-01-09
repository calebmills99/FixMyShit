# dir-cleaner

A Rust CLI tool that recursively deletes empty folders and generates a comprehensive report with a directory tree and file listing sorted by size.

## Features

- **Recursive Empty Folder Deletion**: Removes all empty directories from the bottom up (cascading - if deleting a folder makes its parent empty, that gets deleted too)
- **Dry Run Mode**: Preview what would be deleted without making changes
- **Directory Tree**: Visual tree representation of the folder structure
- **Files by Size Report**: Lists all files sorted from largest to smallest with human-readable sizes
- **Colored Output**: Size-coded file listings (red >100MB, yellow >10MB, blue >1MB)

## Installation

```bash
cargo build --release
```

The binary will be at `target/release/dir-cleaner`.

## Usage

```bash
# Actually delete empty folders and show report
dir-cleaner /path/to/folder

# Dry run - show what would be deleted without deleting
dir-cleaner /path/to/folder --dry-run
```

## Options

| Option | Description |
|--------|-------------|
| `-d, --dry-run` | Preview what would be deleted without making changes |
| `-h, --help` | Show help information |

## Output

The tool generates a three-phase report:

1. **Phase 1**: Lists all empty folders that were (or would be) deleted
2. **Phase 2**: Shows a tree view of the directory structure
3. **Phase 3**: Lists all files sorted by size (largest first), with total size

## Example Output

```
══════════════════════════════════════════════════════════════════════
 Directory Cleaner Report 
══════════════════════════════════════════════════════════════════════

Target folder: "/workspace/my-folder"
Dry run: false

──────────────────────────────────────────────────────────────────────
 Phase 1: Removing Empty Folders 
──────────────────────────────────────────────────────────────────────

Deleted 3 empty folder(s):
  × "/workspace/my-folder/empty1"
  × "/workspace/my-folder/nested/empty2"
  × "/workspace/my-folder/nested"

──────────────────────────────────────────────────────────────────────
 Phase 2: Directory Tree 
──────────────────────────────────────────────────────────────────────

my-folder/
├── docs/
│   └── readme.txt (1.5 KiB)
└── data.bin (10 MiB)

──────────────────────────────────────────────────────────────────────
 Phase 3: Files by Size (Largest → Smallest) 
──────────────────────────────────────────────────────────────────────

Found: 2 files, 10.00 MiB total

          Size  File Path
──────────────────────────────────────────────────────────────────────
        10 MiB  data.bin
       1.5 KiB  docs/readme.txt

══════════════════════════════════════════════════════════════════════
 Report Complete 
══════════════════════════════════════════════════════════════════════
```

## License

MIT
