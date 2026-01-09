use clap::Parser;
use colored::*;
use humansize::{format_size, BINARY};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "dir-cleaner")]
#[command(about = "Recursively deletes empty folders and generates a report")]
struct Args {
    /// The target folder to clean
    #[arg(required = true)]
    folder: PathBuf,

    /// Dry run - show what would be deleted without actually deleting
    #[arg(short, long, default_value_t = false)]
    dry_run: bool,
}

#[derive(Debug)]
struct FileInfo {
    path: PathBuf,
    size: u64,
}

fn main() {
    let args = Args::parse();

    if !args.folder.exists() {
        eprintln!("{} Folder does not exist: {:?}", "Error:".red().bold(), args.folder);
        std::process::exit(1);
    }

    if !args.folder.is_dir() {
        eprintln!("{} Path is not a directory: {:?}", "Error:".red().bold(), args.folder);
        std::process::exit(1);
    }

    let folder = args.folder.canonicalize().unwrap_or(args.folder.clone());

    println!("{}", "═".repeat(70).cyan());
    println!("{}", " Directory Cleaner Report ".cyan().bold());
    println!("{}", "═".repeat(70).cyan());
    println!();
    println!("{} {:?}", "Target folder:".yellow().bold(), folder);
    println!("{} {}", "Dry run:".yellow().bold(), args.dry_run);
    println!();

    // Phase 1: Delete empty folders
    println!("{}", "─".repeat(70).cyan());
    println!("{}", " Phase 1: Removing Empty Folders ".cyan().bold());
    println!("{}", "─".repeat(70).cyan());
    println!();

    let deleted_folders = delete_empty_folders(&folder, args.dry_run);

    if deleted_folders.is_empty() {
        println!("{}", "No empty folders found.".green());
    } else {
        println!(
            "{} {} empty folder(s):",
            if args.dry_run { "Would delete" } else { "Deleted" }.yellow().bold(),
            deleted_folders.len()
        );
        for folder in &deleted_folders {
            println!("  {} {:?}", "×".red(), folder);
        }
    }
    println!();

    // Phase 2: Generate directory tree
    println!("{}", "─".repeat(70).cyan());
    println!("{}", " Phase 2: Directory Tree ".cyan().bold());
    println!("{}", "─".repeat(70).cyan());
    println!();

    let mut visited = HashSet::new();
    print_tree(&folder, 0, &mut HashMap::new(), &mut visited);
    println!();

    // Phase 3: List files by size
    println!("{}", "─".repeat(70).cyan());
    println!("{}", " Phase 3: Files by Size (Largest → Smallest) ".cyan().bold());
    println!("{}", "─".repeat(70).cyan());
    println!();

    let files = collect_files(&folder);

    if files.is_empty() {
        println!("{}", "No files found.".yellow());
    } else {
        let total_size: u64 = files.iter().map(|f| f.size).sum();
        println!(
            "{} {} files, {} total",
            "Found:".green().bold(),
            files.len(),
            format_size(total_size, BINARY).cyan()
        );
        println!();
        println!(
            "{:>14}  {}",
            "Size".underline().bold(),
            "File Path".underline().bold()
        );
        println!("{}", "─".repeat(70));

        for file in &files {
            let size_str = format_size(file.size, BINARY);
            let relative_path = file
                .path
                .strip_prefix(&folder)
                .unwrap_or(&file.path)
                .display();
            
            // Color code by size
            let size_colored = if file.size > 100_000_000 {
                // > 100MB
                format!("{:>14}", size_str).red().bold()
            } else if file.size > 10_000_000 {
                // > 10MB
                format!("{:>14}", size_str).yellow()
            } else if file.size > 1_000_000 {
                // > 1MB
                format!("{:>14}", size_str).blue()
            } else {
                format!("{:>14}", size_str).normal()
            };

            println!("{}  {}", size_colored, relative_path);
        }
    }

    println!();
    println!("{}", "═".repeat(70).cyan());
    println!("{}", " Report Complete ".green().bold());
    println!("{}", "═".repeat(70).cyan());
}

/// Recursively delete empty folders from the bottom up
/// In dry-run mode, simulates cascading deletions to show accurate preview
fn delete_empty_folders(root: &Path, dry_run: bool) -> Vec<PathBuf> {
    let mut deleted = Vec::new();
    let mut dirs: Vec<PathBuf> = Vec::new();

    // Collect all directories (don't follow symlinks)
    for entry in WalkDir::new(root)
        .min_depth(1)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if entry.file_type().is_dir() {
            dirs.push(entry.path().to_path_buf());
        }
    }

    // Sort by depth (deepest first) to delete from bottom up
    dirs.sort_by(|a, b| {
        let depth_a = a.components().count();
        let depth_b = b.components().count();
        depth_b.cmp(&depth_a)
    });

    // Track virtually deleted directories for dry-run cascade simulation
    let mut virtually_deleted: HashSet<PathBuf> = HashSet::new();

    // Delete empty directories
    for dir in dirs {
        let is_empty = if dry_run {
            // In dry-run mode, check if empty considering virtually deleted children
            is_dir_empty_simulated(&dir, &virtually_deleted)
        } else {
            is_dir_empty(&dir)
        };

        if is_empty {
            if dry_run {
                virtually_deleted.insert(dir.clone());
                deleted.push(dir);
            } else {
                match fs::remove_dir(&dir) {
                    Ok(_) => deleted.push(dir),
                    Err(e) => eprintln!("  {} Failed to delete {:?}: {}", "!".red(), dir, e),
                }
            }
        }
    }

    deleted
}

/// Check if a directory is empty (no files or subdirectories)
fn is_dir_empty(path: &Path) -> bool {
    match fs::read_dir(path) {
        Ok(mut entries) => entries.next().is_none(),
        Err(_) => false,
    }
}

/// Check if a directory would be empty after simulated deletions (for dry-run cascade)
fn is_dir_empty_simulated(path: &Path, virtually_deleted: &HashSet<PathBuf>) -> bool {
    match fs::read_dir(path) {
        Ok(entries) => {
            for entry in entries.filter_map(|e| e.ok()) {
                let entry_path = entry.path();
                // If this entry hasn't been virtually deleted, directory is not empty
                if !virtually_deleted.contains(&entry_path) {
                    return false;
                }
            }
            true
        }
        Err(_) => false,
    }
}

/// Print a directory tree (with symlink loop protection)
fn print_tree(
    path: &Path,
    depth: usize,
    last_at_depth: &mut HashMap<usize, bool>,
    visited: &mut HashSet<PathBuf>,
) {
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| path.display().to_string());

    // Build the prefix
    let mut prefix = String::new();
    for d in 0..depth {
        if d == depth - 1 {
            if *last_at_depth.get(&d).unwrap_or(&false) {
                prefix.push_str("└── ");
            } else {
                prefix.push_str("├── ");
            }
        } else if *last_at_depth.get(&d).unwrap_or(&false) {
            prefix.push_str("    ");
        } else {
            prefix.push_str("│   ");
        }
    }

    // Use symlink_metadata to check if this is a symlink (don't follow it)
    let metadata = fs::symlink_metadata(path);
    let is_symlink = metadata.as_ref().map(|m| m.file_type().is_symlink()).unwrap_or(false);
    let is_dir = metadata.as_ref().map(|m| m.file_type().is_dir()).unwrap_or(false);

    if is_symlink {
        // Show symlinks but don't follow them
        let target = fs::read_link(path)
            .map(|t| format!(" -> {}", t.display()))
            .unwrap_or_default();
        println!("{}{}{} {}", prefix, name, target, "(symlink)".dimmed());
        return;
    }

    if is_dir {
        // Check for loops using canonical path
        if let Ok(canonical) = path.canonicalize() {
            if visited.contains(&canonical) {
                println!("{}{}/  {}", prefix, name.blue().bold(), "(recursive, skipped)".yellow());
                return;
            }
            visited.insert(canonical);
        }

        println!("{}{}/", prefix, name.blue().bold());

        let mut entries: Vec<_> = fs::read_dir(path)
            .ok()
            .map(|rd| rd.filter_map(|e| e.ok()).collect())
            .unwrap_or_default();

        // Sort: directories first, then files, alphabetically within each group
        entries.sort_by(|a, b| {
            let a_is_dir = a.file_type().map(|t| t.is_dir()).unwrap_or(false);
            let b_is_dir = b.file_type().map(|t| t.is_dir()).unwrap_or(false);
            match (a_is_dir, b_is_dir) {
                (true, false) => std::cmp::Ordering::Less,
                (false, true) => std::cmp::Ordering::Greater,
                _ => a.file_name().cmp(&b.file_name()),
            }
        });

        let count = entries.len();
        for (i, entry) in entries.iter().enumerate() {
            let is_last = i == count - 1;
            last_at_depth.insert(depth, is_last);
            print_tree(&entry.path(), depth + 1, last_at_depth, visited);
        }
    } else {
        let size = metadata.map(|m| m.len()).unwrap_or(0);
        let size_str = format!("({})", format_size(size, BINARY));
        println!("{}{} {}", prefix, name, size_str.dimmed());
    }
}

/// Collect all files with their sizes, sorted largest to smallest
fn collect_files(root: &Path) -> Vec<FileInfo> {
    let mut files: Vec<FileInfo> = WalkDir::new(root)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .filter_map(|e| {
            let path = e.path().to_path_buf();
            fs::metadata(&path)
                .ok()
                .map(|m| FileInfo { path, size: m.len() })
        })
        .collect();

    // Sort by size descending
    files.sort_by(|a, b| b.size.cmp(&a.size));

    files
}
