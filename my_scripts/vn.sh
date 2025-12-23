#!/usr/bin/env bash

# --- CONFIGURATION ---
# Change this to the absolute path of your vault
VAULT_ROOT="${HOME}/vnotes"

DIR_INBOX="${VAULT_ROOT}/00_inbox"
DIR_ZETTEL="${VAULT_ROOT}/10_zettelkasten"
DIR_PROJECTS="${VAULT_ROOT}/30_projects"
DIR_ATTACHMENTS="${VAULT_ROOT}/90_attachments"

# --- SYSTEM HELPERS ---

# Print error and exit
die() {
    echo "❌ $1" >&2
    exit 1
}

# Ensure directories exist
ensure_dirs() {
    mkdir -p "$DIR_INBOX" "$DIR_ZETTEL" "$DIR_PROJECTS" "$DIR_ATTACHMENTS"
}

# Standardize filename
# Args: $1 = string to standardize, $2 = "true" to allow slashes (optional)
standardize_filename() {
    local input="$1"
    local allow_slashes="$2"

    # Convert to lowercase and normalize (requires iconv for ascii conversion)
    local title=$(echo "$input" | tr '[:upper:]' '[:lower:]' | iconv -f utf-8 -t ascii//TRANSLIT)

    # Replace spaces with underscores
    title="${title// /_}"

    # Remove characters based on allow_slashes flag
    if [[ "$allow_slashes" == "true" ]]; then
        # Allow alphanumeric, underscore, hyphen, slash
        title=$(echo "$title" | sed 's/[^a-z0-9_\-\/]//g')
        # Deduplicate slashes
        title=$(echo "$title" | sed -E 's/\/+/\//g')
        # Trim slashes
        title=$(echo "$title" | sed -E 's/^\///; s/\/$//')
    else
        # Allow alphanumeric, underscore, hyphen
        title=$(echo "$title" | sed 's/[^a-z0-9_\-]//g')
    fi

    # Deduplicate underscores and hyphens
    title=$(echo "$title" | sed -E 's/_+/_/g; s/-+/-/g')

    # Trim leading/trailing underscores and hyphens
    title=$(echo "$title" | sed -E 's/^[_ -]+//; s/[_ -]+$//')

    echo "$title"
}

open_nvim() {
    if [[ -n "$2" ]]; then
        # Launch nvim with Telescope command
        nvim -c "Telescope $2"
    elif [[ -n "$1" ]]; then
        # Launch nvim with specific file
        nvim "$1"
    else
        # Launch nvim empty
        nvim
    fi
}

# --- ACTIONS ---

action_open_note() {
    open_nvim "" "frecency workspace=vnotes"
}

action_search_content() {
    if ! command -v rg &> /dev/null; then
        die "ripgrep (rg) not found. Install with: sudo apt install ripgrep"
    fi
    open_nvim "" "live_grep"
}

action_new_inbox() {
    local title="$1"

    if [[ -z "$title" ]]; then
        die "Error: Title is required\nUsage: vnotes create <title>"
    fi

    local date_prefix=$(date +%Y-%m-%d)
    local timestamp=$(date +%H%M)
    local clean_title=$(standardize_filename "$title" "false")
    local filename="${date_prefix}_${timestamp}_${clean_title}.md"
    local filepath="${DIR_INBOX}/${filename}"

    open_nvim "$filepath"
}

action_new_project() {
    local project_path="$1"

    if [[ -z "$project_path" ]]; then
        echo "❌ Error: Project path is required"
        echo "Usage: vnotes project <project_name/note_title>"
        echo "Example: vnotes project myproject/mynote"
        die "Example: vnotes project mynote  (creates in root)"
    fi

    local project_folder="$DIR_PROJECTS"
    local title=""

    # Check if input contains a slash (nested project)
    if [[ "$project_path" == *"/"* ]]; then
        # Extract directory part and filename part
        local dir_part=$(dirname "$project_path")
        title=$(basename "$project_path")

        local clean_dir=$(standardize_filename "$dir_part" "true")
        project_folder="${DIR_PROJECTS}/${clean_dir}"
        mkdir -p "$project_folder"
    else
        title="$project_path"
    fi

    local clean_title=$(standardize_filename "$title" "false")
    local filepath="${project_folder}/${clean_title}.md"

    if [[ -f "$filepath" ]]; then
        die "Note already exists: $filepath"
    fi

    touch "$filepath"
    open_nvim "$filepath"
}

action_paste_screenshot() {
    local name="$1"
    local date_prefix=$(date +%Y-%m-%d)
    local timestamp=$(date +%H%M%S)
    local filename=""

    if [[ -n "$name" ]]; then
        local clean_name=$(standardize_filename "$name" "false")
        filename="${date_prefix}_${timestamp}_${clean_name}.png"
    else
        filename="${date_prefix}_${timestamp}_screenshot.png"
    fi

    local filepath="${DIR_ATTACHMENTS}/${filename}"

    if ! command -v xclip &> /dev/null; then
        echo "❌ xclip not found. Install with: sudo apt install xclip"
        die "Cannot proceed without xclip."
    fi

    # Save clipboard content to file
    if xclip -selection clipboard -t image/png -o > "$filepath" 2>/dev/null; then
        # Check if file has size (xclip creates empty file if clipboard is empty)
        if [[ ! -s "$filepath" ]]; then
             rm "$filepath"
             die "No image in clipboard or xclip failed."
        fi
        echo "✅ Screenshot saved: ${filename}"
        echo "📋 Markdown link: ![[${filename}]]"
    else
        rm -f "$filepath"
        die "No image in clipboard or xclip error."
    fi
}

action_install() {
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    local bin_dir="${HOME}/.local/bin"
    local symlink_path="${bin_dir}/vn"

    # Ensure ~/.local/bin exists
    mkdir -p "$bin_dir"

    # Check if symlink already exists
    if [[ -L "$symlink_path" ]]; then
        local current_target=$(readlink "$symlink_path")
        if [[ "$current_target" == "$script_path" ]]; then
            echo "✅ Already installed: $symlink_path -> $script_path"
            return 0
        else
            echo "⚠️  Symlink exists but points to different location:"
            echo "   Current: $current_target"
            echo "   New:     $script_path"
            read -p "Replace? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                die "Installation cancelled"
            fi
            rm "$symlink_path"
        fi
    elif [[ -e "$symlink_path" ]]; then
        die "File exists but is not a symlink: $symlink_path"
    fi

    # Create symlink
    if ln -s "$script_path" "$symlink_path"; then
        echo "✅ Installed: $symlink_path -> $script_path"
        echo ""
        echo "Make sure ${bin_dir} is in your PATH."
        echo "Add this to your ~/.bashrc or ~/.zshrc if needed:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    else
        die "Failed to create symlink"
    fi
}

show_help() {
    cat << EOF
usage: vnotes <command> [<args>]

Note management system with Telescope integration (Linux only)

commands:
  search, s, find, open      Search and open notes with Telescope
  grep, g, content           Search note content with Telescope live_grep
  create, c, new, inbox      Create new inbox note
  project, p                 Create new project note
  screenshot, i, img, paste  Paste screenshot from clipboard
  install                    Create symlink at ~/.local/bin/vn

Examples:
  vnotes search
  vnotes grep
  vnotes create My Note Title
  vnotes project myproj/mynote
  vnotes screenshot myimage
  vnotes install
EOF
}

# --- MAIN ---

main() {
    ensure_dirs

    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi

    local cmd="$1"
    shift # Remove command from argument list, leaving only parameters

    case "$cmd" in
        search|s|find|open)
            action_open_note
            ;;
        grep|g|content)
            action_search_content
            ;;
        create|c|new|inbox)
            # Combine remaining args into a single string
            action_new_inbox "$*"
            ;;
        project|p)
            # Combine remaining args (path usually shouldn't have spaces, but just in case)
            action_new_project "$*"
            ;;
        screenshot|i|img|paste)
            action_paste_screenshot "$1"
            ;;
        install)
            action_install
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
