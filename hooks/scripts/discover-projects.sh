#!/bin/bash
# discover-projects.sh — Find all .craft/ projects in a monorepo
# Usage: source this file or run directly
#
# Reads the root .craft/projects/*.md registry (YAML frontmatter).
# Falls back to filesystem scan if no registry exists.
# Output: name|absolute_path|status|package_manager (one per line)
#
# Requires: git repo root detection via git rev-parse

set -e

# Find the git repo root (monorepo root)
_get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Parse YAML frontmatter value from a file
# Usage: _frontmatter_value file.md "key"
_frontmatter_value() {
  local file="$1" key="$2"
  sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null \
    | grep "^${key}:" \
    | head -1 \
    | sed "s/^${key}: *//" \
    | tr -d '"' | tr -d "'"
}

discover_craft_projects() {
  local repo_root
  repo_root=$(_get_repo_root) || return 1

  local registry_dir="$repo_root/.craft/projects"
  local found=0

  # Strategy 1: Read from registry
  if [ -d "$registry_dir" ]; then
    for project_file in "$registry_dir"/*.md; do
      [ -f "$project_file" ] || continue

      local name path status pm
      name=$(_frontmatter_value "$project_file" "name")
      path=$(_frontmatter_value "$project_file" "path")
      status=$(_frontmatter_value "$project_file" "status")
      pm=$(_frontmatter_value "$project_file" "package_manager")

      [ -z "$name" ] && continue

      # Resolve absolute path
      local abs_path
      if [ -z "$path" ] || [ "$path" = "." ]; then
        abs_path="$repo_root"
      else
        abs_path="$repo_root/$path"
      fi

      # Only include if .craft/ actually exists on disk
      if [ -d "$abs_path/.craft" ]; then
        echo "${name}|${abs_path}|${status:-unknown}|${pm:-none}"
        found=$((found + 1))
      fi
    done
  fi

  # Strategy 2: Fallback to filesystem scan if no registry or empty
  if [ "$found" -eq 0 ]; then
    # Find .craft/ dirs (max 3 levels deep, skip node_modules/.git)
    while IFS= read -r craft_dir; do
      local project_dir
      project_dir=$(dirname "$craft_dir")

      # Skip bare/rogue .craft/ directories — require project.md or .global-state
      if [ ! -f "$project_dir/.craft/project.md" ] && [ ! -f "$project_dir/.craft/.global-state" ]; then
        continue
      fi

      local name
      name=$(basename "$project_dir")
      [ "$project_dir" = "$repo_root" ] && name="master"

      local pm=""
      if [ -f "$project_dir/.craft/project.md" ]; then
        pm=$(_frontmatter_value "$project_dir/.craft/project.md" "package_manager")
      fi

      echo "${name}|${project_dir}|unknown|${pm:-none}"
    done < <(find "$repo_root" -maxdepth 4 -name ".craft" -type d \
      -not -path "*/node_modules/*" \
      -not -path "*/.git/*" \
      -not -path "*/plugins/*" \
      2>/dev/null | sort)
  fi
}

# Run if executed directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  discover_craft_projects
fi
