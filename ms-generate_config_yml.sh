#!/usr/bin/env bash
set -euo pipefail
ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/bin ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_brew

# Ensure mas for App Store queries
if command -v brew >/dev/null 2>&1 && ! command -v mas >/dev/null 2>&1; then
  brew install mas >/dev/null 2>&1 || true
fi

{
  echo
  echo "# Generated from current system on $(date)"
  echo
  echo "homebrew_installed_packages:"
  if command -v brew >/dev/null 2>&1; then
    brew leaves --installed-on-request 2>/dev/null | sort | sed 's/^/  - /'
  else
    echo "  # brew not found"
  fi

  echo
  echo "homebrew_cask_apps:"
  if command -v brew >/dev/null 2>&1; then
    cask_tmp="$(mktemp)"
    brew list --cask 2>/dev/null | sort | uniq > "$cask_tmp"

    # Gather normalized brew casks for comparison (portable, no assoc arrays).
    cask_norm_tmp="$(mktemp)"
    while IFS= read -r cask; do
      norm="$(echo "$cask" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
      echo "$norm" >> "$cask_norm_tmp"
    done < "$cask_tmp"
    sort -u "$cask_norm_tmp" -o "$cask_norm_tmp"

    # Detect /Applications/*.app not present in brew list and emit as commented hints.
    manual_tmp="$(mktemp)"
    while IFS= read -r app_path; do
      app_name="$(basename "$app_path" .app)"
      norm_name="$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
      bundle_id="$(defaults read "$app_path/Contents/Info" CFBundleIdentifier 2>/dev/null || true)"
      # Skip App Store apps (have MAS receipt).
      if [[ -f "$app_path/Contents/_MASReceipt/receipt" ]]; then
        continue
      fi
      # Skip apps installed as brew cask symlinks or inside Caskroom.
      if [[ -L "$app_path" ]]; then
        continue
      fi
      resolved_path="$(/usr/bin/realpath "$app_path" 2>/dev/null || true)"
      case "$resolved_path" in
        *Caskroom*|*Homebrew*|*/Cellar/*) continue ;;
      esac
      # Skip Karabiner aux apps; covered by karabiner-elements cask.
      if [[ "$app_name" == ".Karabiner-VirtualHIDDevice-Manager" || "$app_name" == "Karabiner-VirtualHIDDevice-Manager" || "$app_name" == "Karabiner-EventViewer" ]]; then
        continue
      fi
      if ! grep -Fxq "$norm_name" "$cask_norm_tmp"; then
        # Known token overrides.
        case "$app_name" in
          "Parallels Desktop") suggested_token="parallels@18" ;;
          "iTerm") suggested_token="iterm2" ;;
          "NTFS for Mac") suggested_token="paragon-ntfs" ;;
          "Karabiner-Elements") suggested_token="karabiner-elements" ;;
          "DisplayLink Manager") suggested_token="displaylink" ;;
          *) suggested_token="$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\\+/-/g; s/^-//; s/-$//')" ;;
        esac

        # Build candidate tokens from name and bundle_id.
        candidates=()
        candidates+=("$suggested_token")
        candidates+=("$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')")
        if [[ -n "$bundle_id" ]]; then
          # Take last segment and vendor-product forms.
          last_seg="${bundle_id##*.}"
          candidates+=("$(echo "$last_seg" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')")  # last segment
          vendor_prod="$(echo "$bundle_id" | awk -F. '{print $(NF-1) "-" $NF}')"
          candidates+=("$(echo "$vendor_prod" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--/-/g; s/^-//; s/-$//')")
        fi

        matched=""
        for cand in "${candidates[@]}"; do
          if [[ -n "$cand" ]] && brew info --cask "$cand" >/dev/null 2>&1; then
            matched="$cand"
            break
          fi
        done

        if [[ -n "$matched" ]]; then
          echo "$matched" >> "$cask_tmp"   # add to cask list automatically
        else
          printf "  # manual app: %s (%s) -> '%s' [no brew cask]\n" "$app_name" "$app_path" "${candidates[0]}" >> "$manual_tmp"
        fi
      fi
    done < <(find /Applications -maxdepth 1 -name "*.app" -prune 2>/dev/null | sort)

    sort -u "$cask_tmp" | sed 's/^/  - /'
    if [[ -s "$manual_tmp" ]]; then
      cat "$manual_tmp"
    fi

    rm -f "$manual_tmp"
    rm -f "$cask_tmp" "$cask_norm_tmp"
  else
    echo "  # brew not found"
  fi

  echo
  echo "mas_installed_app_ids:"
  if command -v mas >/dev/null 2>&1; then
    mas list 2>/dev/null | while IFS= read -r line; do
      # Example line: 497799835 Xcode (14.3.1)
      id="${line%% *}"        # first field = ID
      rest="${line#* }"       # everything after ID
      name_with_ver="${rest}" # "Xcode (14.3.1)"
      # Strip the trailing " (…)" version part:
      name="${name_with_ver% (*}"
      # Escape double quotes in name for YAML safety
      name_escaped="${name//\"/\\\"}"
      echo "  - { id: ${id}, name: \"${name_escaped}\" }"
    done
  else
    echo "  # mas not found"
  fi
} | tee config.yml
