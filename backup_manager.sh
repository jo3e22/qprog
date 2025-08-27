#!/bin/bash

backup_manager() {
  local current_file=$1
  local backup_file=$2
  
  # Check if files exist
  [ ! -f "$current_file" ] && { echo "Current file not found: $current_file"; exit 1; }
  [ ! -f "$backup_file" ] && { echo "Backup file not found: $backup_file"; exit 1; }
  
  # Show file info
  echo "Current: $current_file ($(stat -c %y "$current_file"))"
  echo "Backup:  $backup_file ($(stat -c %y "$backup_file"))"
  echo
  
  # Check if identical
  if cmp -s "$current_file" "$backup_file"; then
    echo "Files are identical"
    read -p "Delete backup? (y/N): " delete_backup
    [ "$delete_backup" = "y" ] && rm "$backup_file" && echo "Backup deleted"
    exit 0
  fi
  
  # Show options
  echo "Files differ. Options:"
  echo "1) Show unified diff"
  echo "2) Show side-by-side diff"  
  echo "3) Interactive merge (vimdiff)"
  echo "4) Use backup (replace current)"
  echo "5) Use current (update backup)"
  echo "6) Keep both unchanged"
  
  read -p "Choose (1-6): " choice
  
  case $choice in
    1) diff -u "$backup_file" "$current_file" | less;;
    2) diff -y "$backup_file" "$current_file" | less;;
    3) 
      # Create temporary merged file
      cp "$current_file" "${current_file}.merged"
      vimdiff "$backup_file" "${current_file}.merged"
      read -p "Use merged version? (y/N): " use_merged
      if [ "$use_merged" = "y" ]; then
        mv "${current_file}.merged" "$current_file"
        echo "Applied merged changes"
      else
        rm "${current_file}.merged"
        echo "Merge cancelled"
      fi
      ;;
    4) 
      cp "$current_file" "${current_file}.before_restore"
      cp "$backup_file" "$current_file"
      echo "Restored from backup. Original saved as ${current_file}.before_restore"
      ;;
    5)
      cp "$current_file" "$backup_file"
      echo "Updated backup with current version"
      ;;
    6) echo "No changes made";;
    *) echo "Invalid option";;
  esac
}

search_files() {
  local filestring=$1
  local local_dir=$2
  local suffix=$3
  
  if [ $# -lt 3 ]; then
    suffix=""
  fi

  echo "DEBUG: Searching for pattern '*${filestring}*${suffix}' in directory '$local_dir'" >&2

  local local_files=($(find "$local_dir" -name "*${filestring}*${suffix}" 2>/dev/null | sort -t_ -k1,1 -r))
  
  if [ ${#local_files[@]} -eq 0 ]; then
    echo "No files found matching '$filestring' in $local_dir" >&2
    return 1
  elif [ ${#local_files[@]} -eq 1 ]; then
    # Only one file found, return it
    echo "${local_files[0]}"
    return 0
  else
    # Multiple files found, let user choose
    echo "Multiple files found matching '$filestring':" >&2
    for i in "${!local_files[@]}"; do
      echo "$((i+1))) ${local_files[i]}" >&2
    done
    echo >&2
    read -p "Choose file (1-${#local_files[@]}): " choice >&2
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#local_files[@]} ]; then
      selected_file="${local_files[$((choice-1))]}"
      echo "Selected: $selected_file" >&2  
      echo "$selected_file"  # Return the selected file
      return 0
    else
      echo "Invalid choice" >&2
      return 1
    fi
  fi
}

# Parse command line options
backup_dir="backups"
current_suffix=""
backup_suffix=".bak"

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--suffix)
      current_suffix="$2"
      shift 2
      ;;
    -b|--backup-suffix)
      backup_suffix="$2"
      shift 2
      ;;
    -d|--backup-dir)
      backup_dir="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS] <current_file> [backup_file]"
      echo "   or: $0 [OPTIONS] <filename_pattern>"
      echo
      echo "Options:"
      echo "  -s, --suffix SUFFIX          Suffix for current file search (default: none)"
      echo "  -b, --backup-suffix SUFFIX   Suffix for backup file search (default: .bak)"
      echo "  -d, --backup-dir DIR         Directory to search for backups (default: backups)"
      echo "  -h, --help                   Show this help message"
      echo
      echo "Examples:"
      echo "  $0 testob_h.f90                           # Use exact file + search for *.bak"
      echo "  $0 testob                                 # Search for *testob* + *testob*.bak"
      echo "  $0 -s .f90 testob                         # Search for *testob*.f90 + *testob*.bak"
      echo "  $0 -b .backup testob                      # Search for *testob* + *testob*.backup"
      echo "  $0 -s .f90 -b .backup testob              # Search for *testob*.f90 + *testob*.backup"
      echo "  $0 -d old_backups testob                  # Search in old_backups/ directory"
      echo "  $0 testob_h.f90 specific_backup.bak       # Compare specific files"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      # First non-option argument
      if [ -z "$input_file" ]; then
        input_file="$1"
      elif [ -z "$backup_file_arg" ]; then
        backup_file_arg="$1"
      else
        echo "Too many arguments" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Main logic
if [ -n "$backup_file_arg" ]; then
  # Two files provided - compare directly
  backup_manager "$input_file" "$backup_file_arg"
elif [ -n "$input_file" ]; then
  # One file provided - search for matching files
  
  # Check if exact file exists
  if [ -f "$input_file" ] && [[ "$input_file" == *.* ]]; then
    # Also search for pattern matches
    pattern_file=$(search_files "$(basename "$input_file")" "." "$current_suffix" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$pattern_file" != "$input_file" ]; then
      echo "Found exact file: $input_file" >&2
      echo "Found pattern match: $pattern_file" >&2
      read -p "Use exact file (e) or pattern match (p)? " choice >&2
      
      case $choice in
        p|P) current_file="$pattern_file";;
        *) current_file="$input_file";;
      esac
    else
      current_file="$input_file"
    fi
  else
    # Search for files matching the pattern in current directory
    current_file=$(search_files "$(basename "$input_file")" "." "$current_suffix")
    if [ $? -ne 0 ]; then
      echo "Current file not found"
      exit 1
    fi
  fi

  # Find the backup file
  filename=$(basename "$current_file")
  # Remove current suffix from filename for backup search
  if [ -n "$current_suffix" ]; then
    filename="${filename%$current_suffix}"
  fi
  
  backup_file=$(search_files "$filename" "$backup_dir" "$backup_suffix")
  if [ $? -ne 0 ]; then
    echo "No backup found for '$filename' with suffix '$backup_suffix'"
    exit 1
  fi

  # Now compare the files
  backup_manager "$current_file" "$backup_file"
else
  echo "Usage: $0 [OPTIONS] <current_file> [backup_file]"
  echo "Use --help for more information"
  exit 1
fi