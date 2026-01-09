use std::cmp::Ordering;
use std::env;
use std::ffi::OsStr;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

#[derive(Debug, Clone)]
struct FileInfo {
    path: PathBuf,
    rel_path: PathBuf,
    size_bytes: u64,
    modified: Option<SystemTime>,
    kind: EntryKind,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum EntryKind {
    File,
    Symlink,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let (target, dry_run) = match parse_args(&args) {
        Ok(v) => v,
        Err(msg) => {
            eprintln!("{msg}");
            print_usage(&args.get(0).map(String::as_str).unwrap_or("dir_cleaner"));
            std::process::exit(2);
        }
    };

    if let Err(e) = run(&target, dry_run) {
        eprintln!("error: {e}");
        std::process::exit(1);
    }
}

fn parse_args(args: &[String]) -> Result<(PathBuf, bool), String> {
    let mut dry_run = false;
    let mut path: Option<PathBuf> = None;

    for arg in args.iter().skip(1) {
        match arg.as_str() {
            "--dry-run" | "-n" => dry_run = true,
            "--help" | "-h" => return Err(String::new()),
            _ if arg.starts_with('-') => return Err(format!("unknown flag: {arg}")),
            _ => {
                if path.is_some() {
                    return Err("too many positional arguments (expected only <FOLDER>)".into());
                }
                path = Some(PathBuf::from(arg));
            }
        }
    }

    let path = path.ok_or_else(|| "missing required argument: <FOLDER>".to_string())?;
    Ok((path, dry_run))
}

fn print_usage(bin: &str) {
    eprintln!(
        "Usage:\n  {bin} <FOLDER> [--dry-run]\n\n\
Deletes empty directories recursively (bottom-up), then prints:\n\
- a tree view of the folder\n\
- a list of all files within the folder sorted by size (largest -> smallest)\n\n\
Notes:\n\
- symlinks are not followed (they are shown as entries)\n\
- the root folder itself is never deleted\n"
    );
}

fn run(target: &Path, dry_run: bool) -> io::Result<()> {
    let root = canonicalize_best_effort(target)?;
    if !root.is_dir() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("not a directory: {}", root.display()),
        ));
    }

    let mut deleted_dirs: Vec<PathBuf> = Vec::new();
    prune_empty_dirs(&root, &root, dry_run, &mut deleted_dirs)?;

    // Re-scan after deletions for reporting.
    let mut files: Vec<FileInfo> = Vec::new();
    gather_files(&root, &root, &mut files)?;
    files.sort_by(|a, b| {
        match b.size_bytes.cmp(&a.size_bytes) {
            Ordering::Equal => a.rel_path.to_string_lossy().cmp(&b.rel_path.to_string_lossy()),
            other => other,
        }
    });

    println!("== Empty directory cleanup report ==");
    println!("Root: {}", root.display());
    println!("Dry run: {}", if dry_run { "yes" } else { "no" });
    println!();

    if deleted_dirs.is_empty() {
        println!("Deleted empty directories: 0");
    } else {
        println!("Deleted empty directories: {}", deleted_dirs.len());
        deleted_dirs.sort();
        for d in &deleted_dirs {
            let rel = d.strip_prefix(&root).unwrap_or(d);
            println!("- {}", rel.display());
        }
    }

    println!();
    println!("== Tree ==");
    print_tree(&root)?;

    println!();
    println!("== Files by size (largest -> smallest) ==");
    if files.is_empty() {
        println!("(no files found)");
    } else {
        for f in &files {
            let kind = match f.kind {
                EntryKind::File => "",
                EntryKind::Symlink => " (symlink)",
            };
            println!(
                "{}\t{}\t{}{}",
                format!("{:>12}", f.size_bytes),
                format!("{:>8}", human_bytes(f.size_bytes)),
                f.rel_path.display(),
                kind
            );
        }
    }

    Ok(())
}

fn canonicalize_best_effort(path: &Path) -> io::Result<PathBuf> {
    match fs::canonicalize(path) {
        Ok(p) => Ok(p),
        Err(_) => Ok(path.to_path_buf()),
    }
}

fn prune_empty_dirs(
    dir: &Path,
    root: &Path,
    dry_run: bool,
    deleted_dirs: &mut Vec<PathBuf>,
) -> io::Result<()> {
    // Post-order traversal: prune children first, then remove current dir if empty (and not root).
    let entries = match fs::read_dir(dir) {
        Ok(rd) => rd,
        Err(e) => {
            eprintln!("warn: cannot read dir {}: {e}", dir.display());
            return Ok(());
        }
    };

    for entry in entries {
        let entry = match entry {
            Ok(e) => e,
            Err(e) => {
                eprintln!("warn: cannot read dir entry in {}: {e}", dir.display());
                continue;
            }
        };
        let path = entry.path();

        let ft = match entry.file_type() {
            Ok(t) => t,
            Err(e) => {
                eprintln!("warn: cannot stat {}: {e}", path.display());
                continue;
            }
        };
        if ft.is_dir() && !ft.is_symlink() {
            prune_empty_dirs(&path, root, dry_run, deleted_dirs)?;
        }
    }

    // Never delete the root folder.
    if dir == root {
        return Ok(());
    }

    // "Empty folder" means: no entries at all (including symlinks).
    let is_empty = match fs::read_dir(dir) {
        Ok(mut rd) => rd.next().is_none(),
        Err(e) => {
            eprintln!("warn: cannot re-check emptiness of {}: {e}", dir.display());
            false
        }
    };

    if is_empty {
        if dry_run {
            deleted_dirs.push(dir.to_path_buf());
        } else {
            match fs::remove_dir(dir) {
                Ok(()) => deleted_dirs.push(dir.to_path_buf()),
                Err(e) => {
                    // Another process could have created a file, or permission issues, etc.
                    eprintln!("warn: could not remove dir {}: {e}", dir.display());
                }
            }
        }
    }

    Ok(())
}

fn gather_files(root: &Path, dir: &Path, out: &mut Vec<FileInfo>) -> io::Result<()> {
    let entries = match fs::read_dir(dir) {
        Ok(rd) => rd,
        Err(e) => {
            eprintln!("warn: cannot read dir {}: {e}", dir.display());
            return Ok(());
        }
    };

    for entry in entries {
        let entry = match entry {
            Ok(e) => e,
            Err(e) => {
                eprintln!("warn: cannot read dir entry in {}: {e}", dir.display());
                continue;
            }
        };
        let path = entry.path();

        // Use symlink_metadata so we can classify symlinks without following them.
        let meta = match fs::symlink_metadata(&path) {
            Ok(m) => m,
            Err(e) => {
                eprintln!("warn: cannot stat {}: {e}", path.display());
                continue;
            }
        };
        let ft = meta.file_type();

        if ft.is_dir() && !ft.is_symlink() {
            gather_files(root, &path, out)?;
            continue;
        }

        if ft.is_file() || ft.is_symlink() {
            let rel_path = path.strip_prefix(root).unwrap_or(&path).to_path_buf();
            out.push(FileInfo {
                path,
                rel_path,
                size_bytes: meta.len(),
                modified: meta.modified().ok(),
                kind: if ft.is_symlink() {
                    EntryKind::Symlink
                } else {
                    EntryKind::File
                },
            });
        }
    }

    Ok(())
}

fn print_tree(root: &Path) -> io::Result<()> {
    println!("{}/", root.file_name().unwrap_or(OsStr::new(".")).to_string_lossy());
    let mut prefix = String::new();
    print_tree_inner(root, &mut prefix)?;
    Ok(())
}

fn print_tree_inner(dir: &Path, prefix: &mut String) -> io::Result<()> {
    let mut items: Vec<(String, PathBuf, fs::FileType)> = Vec::new();

    let entries = match fs::read_dir(dir) {
        Ok(rd) => rd,
        Err(e) => {
            eprintln!("warn: cannot read dir {}: {e}", dir.display());
            return Ok(());
        }
    };

    for entry in entries {
        let entry = match entry {
            Ok(e) => e,
            Err(e) => {
                eprintln!("warn: cannot read dir entry in {}: {e}", dir.display());
                continue;
            }
        };
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();
        let ft = match entry.file_type() {
            Ok(t) => t,
            Err(e) => {
                eprintln!("warn: cannot stat {}: {e}", path.display());
                continue;
            }
        };
        items.push((name, path, ft));
    }

    // Deterministic: directories first, then files; then name.
    items.sort_by(|a, b| {
        let a_is_dir = a.2.is_dir() && !a.2.is_symlink();
        let b_is_dir = b.2.is_dir() && !b.2.is_symlink();
        match (a_is_dir, b_is_dir) {
            (true, false) => Ordering::Less,
            (false, true) => Ordering::Greater,
            _ => a.0.cmp(&b.0),
        }
    });

    let last_index = items.len().saturating_sub(1);
    for (i, (name, path, ft)) in items.into_iter().enumerate() {
        let is_last = i == last_index;
        let branch = if is_last { "└── " } else { "├── " };
        let next_prefix_add = if is_last { "    " } else { "│   " };

        if ft.is_dir() && !ft.is_symlink() {
            println!("{prefix}{branch}{name}/");
            let old_len = prefix.len();
            prefix.push_str(next_prefix_add);
            print_tree_inner(&path, prefix)?;
            prefix.truncate(old_len);
        } else if ft.is_symlink() {
            println!("{prefix}{branch}{name}@");
        } else {
            let size = fs::metadata(&path).map(|m| m.len()).unwrap_or(0);
            println!("{prefix}{branch}{name} ({})", human_bytes(size));
        }
    }

    Ok(())
}

fn human_bytes(bytes: u64) -> String {
    const UNITS: [&str; 6] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let mut v = bytes as f64;
    let mut idx = 0usize;
    while v >= 1024.0 && idx + 1 < UNITS.len() {
        v /= 1024.0;
        idx += 1;
    }
    if idx == 0 {
        format!("{bytes} {}", UNITS[idx])
    } else if v >= 10.0 {
        format!("{:.1} {}", v, UNITS[idx])
    } else {
        format!("{:.2} {}", v, UNITS[idx])
    }
}

