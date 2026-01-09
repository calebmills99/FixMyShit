use clap::Parser;
use humansize::{format_size, DECIMAL};
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// The directory to clean up and analyze
    #[arg(default_value = ".")]
    path: PathBuf,
}

fn main() -> io::Result<()> {
    let args = Args::parse();
    let root_path = args.path;

    if !root_path.exists() {
        eprintln!("Error: Path '{}' does not exist.", root_path.display());
        std::process::exit(1);
    }

    if !root_path.is_dir() {
        eprintln!("Error: Path '{}' is not a directory.", root_path.display());
        std::process::exit(1);
    }

    println!("Starting cleanup on: {}", root_path.display());

    // 1. Remove empty directories recursively
    let removed_count = remove_empty_dirs(&root_path, true)?;
    println!("Cleanup complete. Removed {} empty directories.", removed_count);
    println!("--------------------------------------------------");

    // 2. Print Tree Structure
    println!("Directory Tree:");
    print_tree(&root_path, "")?;
    println!("--------------------------------------------------");

    // 3. List files by size (largest -> smallest)
    println!("Files by Size (Largest to Smallest):");
    list_files_by_size(&root_path)?;

    Ok(())
}

/// Recursively removes empty directories.
/// Returns the number of directories removed.
/// `is_root` prevents the root directory itself from being removed.
fn remove_empty_dirs(path: &Path, is_root: bool) -> io::Result<usize> {
    let mut removed_count = 0;
    
    if !path.is_dir() {
        return Ok(0);
    }

    // Read entries
    let entries = fs::read_dir(path)?;
    let mut is_empty = true;

    for entry in entries {
        let entry = entry?;
        let path = entry.path();

        if path.is_dir() {
            // Recurse
            removed_count += remove_empty_dirs(&path, false)?;
            // Check if it still exists (it might have been removed if it was empty)
            if path.exists() {
                is_empty = false;
            }
        } else {
            is_empty = false;
        }
    }

    // If we are not root, and we are empty, delete ourselves
    if !is_root && is_empty {
        // Double check it's actually empty before removing to avoid race conditions or errors
        // read_dir is a bit expensive but safe.
        // Actually, we just iterated. If is_empty is true, we saw no files and all subdirs were removed or didn't exist.
        match fs::remove_dir(path) {
            Ok(_) => {
                // println!("Removed empty directory: {}", path.display());
                removed_count += 1;
            }
            Err(e) => {
                eprintln!("Failed to remove {}: {}", path.display(), e);
            }
        }
    }

    Ok(removed_count)
}

/// Prints a tree structure of the directory
fn print_tree(dir: &Path, prefix: &str) -> io::Result<()> {
    let dir_name = dir.file_name()
        .unwrap_or_else(|| dir.as_os_str())
        .to_string_lossy();
    
    // Only print the root name if prefix is empty, otherwise we rely on recursive printing
    if prefix.is_empty() {
        println!("{}", dir_name);
    }

    let mut entries = fs::read_dir(dir)?
        .map(|res| res.map(|e| e.path()))
        .collect::<Result<Vec<_>, io::Error>>()?;

    // Sort for consistent output
    entries.sort();

    for (i, entry) in entries.iter().enumerate() {
        let is_last = i == entries.len() - 1;
        let connector = if is_last { "└── " } else { "├── " };
        let new_prefix = if is_last { "    " } else { "│   " };

        let name = entry.file_name()
            .unwrap_or_else(|| entry.as_os_str())
            .to_string_lossy();

        println!("{}{}{}", prefix, connector, name);

        if entry.is_dir() {
            let next_prefix = format!("{}{}", prefix, new_prefix);
            print_tree(entry, &next_prefix)?;
        }
    }

    Ok(())
}

struct FileInfo {
    path: PathBuf,
    size: u64,
}

fn list_files_by_size(root: &Path) -> io::Result<()> {
    let mut files = Vec::new();

    for entry in WalkDir::new(root) {
        let entry = entry.map_err(|e| io::Error::new(io::ErrorKind::Other, e))?;
        if entry.file_type().is_file() {
            let metadata = entry.metadata().map_err(|e| io::Error::new(io::ErrorKind::Other, e))?;
            files.push(FileInfo {
                path: entry.path().to_path_buf(),
                size: metadata.len(),
            });
        }
    }

    // Sort descending by size
    files.sort_by(|a, b| b.size.cmp(&a.size));

    for file in files {
        let size_str = format_size(file.size, DECIMAL);
        // Try to make path relative to root for cleaner output
        let display_path = file.path.strip_prefix(root).unwrap_or(&file.path);
        println!("{:<10} {}", size_str, display_path.display());
    }

    Ok(())
}
