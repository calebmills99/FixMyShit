use chrono::Local;
use clap::Parser;
use colored::*;
use humansize::{format_size, BINARY};
use std::collections::{HashMap, HashSet};
use std::fs::{self, File};
use std::io::{self, Write};
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

/// A writer that writes to both stdout and a file
struct TeeWriter {
    file: File,
}

impl TeeWriter {
    fn new(file: File) -> Self {
        TeeWriter { file }
    }

    fn write_line(&mut self, line: &str) -> io::Result<()> {
        println!("{}", line);
        writeln!(self.file, "{}", strip_ansi_codes(line))
    }

    fn write_empty_line(&mut self) -> io::Result<()> {
        println!();
        writeln!(self.file)
    }
}

/// Strip ANSI color codes from a string for plain text log output
fn strip_ansi_codes(s: &str) -> String {
    let re = regex::Regex::new(r"\x1b\[[0-9;]*m").unwrap();
    re.replace_all(s, "").to_string()
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

    // Create log file in the target directory
    let timestamp = Local::now().format("%Y%m%d_%H%M%S");
    let log_filename = format!("dir-cleaner-report_{}.log", timestamp);
    let log_path = folder.join(&log_filename);
    
    let log_file = match File::create(&log_path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("{} Failed to create log file {:?}: {}", "Error:".red().bold(), log_path, e);
            std::process::exit(1);
        }
    };

    let mut writer = TeeWriter::new(log_file);

    writer.write_line(&"═".repeat(70)).unwrap();
    writer.write_line(" Directory Cleaner Report ").unwrap();
    writer.write_line(&"═".repeat(70)).unwrap();
    writer.write_empty_line().unwrap();
    writer.write_line(&format!("Target folder: {:?}", folder)).unwrap();
    writer.write_line(&format!("Dry run: {}", args.dry_run)).unwrap();
    writer.write_line(&format!("Log file: {:?}", log_path)).unwrap();
    writer.write_empty_line().unwrap();

    // Phase 1: Delete empty folders
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_line(" Phase 1: Removing Empty Folders ").unwrap();
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_empty_line().unwrap();

    let deleted_folders = delete_empty_folders(&folder, args.dry_run);

    if deleted_folders.is_empty() {
        writer.write_line("No empty folders found.").unwrap();
    } else {
        writer.write_line(&format!(
            "{} {} empty folder(s):",
            if args.dry_run { "Would delete" } else { "Deleted" },
            deleted_folders.len()
        )).unwrap();
        for folder in &deleted_folders {
            writer.write_line(&format!("  × {:?}", folder)).unwrap();
        }
    }
    writer.write_empty_line().unwrap();

    // Phase 2: Generate directory tree
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_line(" Phase 2: Directory Tree ").unwrap();
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_empty_line().unwrap();

    let mut visited = HashSet::new();
    let mut tree_output = Vec::new();
    print_tree_to_vec(&folder, 0, &mut HashMap::new(), &mut visited, &mut tree_output);
    for line in &tree_output {
        writer.write_line(line).unwrap();
    }
    writer.write_empty_line().unwrap();

    // Phase 3: List files by size
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_line(" Phase 3: Files by Size (Largest → Smallest) ").unwrap();
    writer.write_line(&"─".repeat(70)).unwrap();
    writer.write_empty_line().unwrap();

    let files = collect_files(&folder);

    if files.is_empty() {
        writer.write_line("No files found.").unwrap();
    } else {
        let total_size: u64 = files.iter().map(|f| f.size).sum();
        writer.write_line(&format!(
            "Found: {} files, {} total",
            files.len(),
            format_size(total_size, BINARY)
        )).unwrap();
        writer.write_empty_line().unwrap();
        writer.write_line(&format!("{:>14}  {}", "Size", "File Path")).unwrap();
        writer.write_line(&"─".repeat(70)).unwrap();

        for file in &files {
            let size_str = format_size(file.size, BINARY);
            let relative_path = file
                .path
                .strip_prefix(&folder)
                .unwrap_or(&file.path)
                .display();
            
            writer.write_line(&format!("{:>14}  {}", size_str, relative_path)).unwrap();
        }
    }

    writer.write_empty_line().unwrap();
    writer.write_line(&"═".repeat(70)).unwrap();
    writer.write_line(" Report Complete ").unwrap();
    writer.write_line(&"═".repeat(70)).unwrap();
    writer.write_empty_line().unwrap();
    writer.write_line(&format!("Report saved to: {:?}", log_path)).unwrap();

    // Also print with colors for terminal
    println!();
    println!("{} {:?}", "Report saved to:".green().bold(), log_path);
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

/// Print a directory tree to a Vec (with symlink loop protection)
fn print_tree_to_vec(
    path: &Path,
    depth: usize,
    last_at_depth: &mut HashMap<usize, bool>,
    visited: &mut HashSet<PathBuf>,
    output: &mut Vec<String>,
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
        output.push(format!("{}{}{} (symlink)", prefix, name, target));
        return;
    }

    if is_dir {
        // Check for loops using canonical path
        if let Ok(canonical) = path.canonicalize() {
            if visited.contains(&canonical) {
                output.push(format!("{}{}/  (recursive, skipped)", prefix, name));
                return;
            }
            visited.insert(canonical);
        }

        output.push(format!("{}{}/", prefix, name));

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
            print_tree_to_vec(&entry.path(), depth + 1, last_at_depth, visited, output);
        }
    } else {
        let size = metadata.map(|m| m.len()).unwrap_or(0);
        let size_str = format!("({})", format_size(size, BINARY));
        output.push(format!("{}{} {}", prefix, name, size_str));
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
