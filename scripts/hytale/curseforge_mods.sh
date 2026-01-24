#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# CurseForge Mod Downloader
# Uses cflookup.com to get mod info and forgecdn.net for downloads
# Maintains a manifest to track downloads and clean up removed mods

CFLOOKUP_URL="https://cflookup.com"
FORGECDN_URL="https://mediafilez.forgecdn.net/files"
MOD_DIR="${HYTALE_MOD_DIR:-$GAME_DIR/mods}"
MANIFEST_FILE="$MOD_DIR/.curseforge_manifest.json"

# --- Manifest Functions ---

init_manifest() {
    mkdir -p "$MOD_DIR"
    [ -f "$MANIFEST_FILE" ] || echo '{"mods":{}}' > "$MANIFEST_FILE"
}

get_from_manifest() {
    jq -r ".mods[\"$1\"].$2 // empty" "$MANIFEST_FILE" 2>/dev/null
}

update_manifest() {
    local mod_id="$1" file_id="$2" file_name="$3" mod_name="$4"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg mid "$mod_id" \
       --arg fid "$file_id" \
       --arg fn "$file_name" \
       --arg mn "$mod_name" \
       --arg ts "$timestamp" \
       '.mods[$mid] = {modId: ($mid | tonumber), modName: $mn, fileName: $fn, fileId: $fid, downloadedAt: $ts}' \
       "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
}

remove_from_manifest() {
    jq --arg mid "$1" 'del(.mods[$mid])' "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && \
        mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
}

# --- Utility Functions ---

# Convert file ID to forgecdn path format
# e.g., 7453942 -> 7453/942, 7453042 -> 7453/42
format_file_id() {
    local file_id="$1"
    local first_part="${file_id%???}"
    local second_part="${file_id#"$first_part"}"
    # Remove leading zeros from second part
    second_part=$(printf '%s' "$second_part" | sed 's/^0*//')
    [ -z "$second_part" ] && second_part="0"
    printf '%s/%s' "$first_part" "$second_part"
}

# --- HTTP/Parsing Functions ---

fetch_page() {
    curl -fsSL --connect-timeout 10 --max-time 30 "$1" 2>/dev/null
}

# Parse mod name from cflookup HTML
parse_mod_name() {
    # Look for: <a class="text-white" href="...">ModName</a>
    printf '%s' "$1" | sed -n 's/.*class="text-white"[^>]*>[[:space:]]*\([^<]*\)<.*/\1/p' | head -1 | tr -d '\n\r'
}

# Parse latest file info from cflookup HTML
# Returns: filename|fileid
parse_latest_file() {
    local html="$1"
    local filename fileid
    
    # Extract jar filename
    filename=$(printf '%s' "$html" | sed -n 's/.*<td>\([^<]*\.jar\)<\/td>.*/\1/p' | head -1 | tr -d ' \n\r')
    
    # Extract file ID from install button link
    fileid=$(printf '%s' "$html" | sed -n 's/.*fileId=\([0-9]*\).*/\1/p' | head -1)
    
    [ -n "$filename" ] && [ -n "$fileid" ] && printf '%s|%s' "$filename" "$fileid"
}

download_file() {
    local url="$1" dest="$2"
    
    if curl -fsSL --connect-timeout 10 --max-time 120 -o "$dest" "$url" 2>/dev/null; then
        [ -s "$dest" ] && return 0
    fi
    rm -f "$dest" 2>/dev/null
    return 1
}

# --- Main Logic ---

log_section "CurseForge Mod Downloader"

# Check if enabled
if [ -z "${CURSEFORGE_MOD_IDS:-}" ]; then
    # If manifest exists, clean up all managed mods
    if [ -f "$MANIFEST_FILE" ]; then
        log_step "Cleanup"
        printf "${YELLOW}CURSEFORGE_MOD_IDS empty, removing managed mods${NC}\n"
        
        manifest_mods=$(jq -r '.mods | keys[]' "$MANIFEST_FILE" 2>/dev/null) || true
        for mod_id in $manifest_mods; do
            [ -z "$mod_id" ] && continue
            filename=$(jq -r ".mods[\"$mod_id\"].fileName // empty" "$MANIFEST_FILE" 2>/dev/null)
            if [ -n "$filename" ] && [ -f "$MOD_DIR/$filename" ]; then
                rm -f "$MOD_DIR/$filename"
                printf "      ${DIM}↳ Removed:${NC} ${YELLOW}%s${NC}\n" "$filename"
            fi
        done
        rm -f "$MANIFEST_FILE"
        printf "      ${DIM}↳ Manifest cleared${NC}\n"
    else
        log_step "CurseForge Mods"
        printf "${DIM}not configured (set CURSEFORGE_MOD_IDS)${NC}\n"
    fi
    exit 0
fi

init_manifest

# Parse mod IDs (comma or space separated)
MOD_ID_LIST=$(printf '%s' "$CURSEFORGE_MOD_IDS" | tr ',' ' ')

# Counters
CURRENT_MODS=""
DOWNLOAD_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

log_step "Processing Mods"
printf "\n"

for mod_id in $MOD_ID_LIST; do
    # Trim whitespace
    mod_id=$(printf '%s' "$mod_id" | tr -d ' \t\n\r')
    [ -z "$mod_id" ] && continue
    
    CURRENT_MODS="$CURRENT_MODS $mod_id"
    printf "      ${DIM}↳ Mod ID:${NC} %s " "$mod_id"
    
    # Fetch mod page
    html=$(fetch_page "$CFLOOKUP_URL/$mod_id") || {
        printf "${RED}lookup failed${NC}\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    }
    
    # Parse mod info
    mod_name=$(parse_mod_name "$html")
    [ -z "$mod_name" ] && mod_name="Mod-$mod_id"
    
    file_info=$(parse_latest_file "$html")
    if [ -z "$file_info" ]; then
        printf "${YELLOW}no files found${NC}\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi
    
    file_name="${file_info%%|*}"
    file_id="${file_info##*|}"
    
    # Check if already up-to-date
    manifest_file_id=$(get_from_manifest "$mod_id" "fileId")
    manifest_filename=$(get_from_manifest "$mod_id" "fileName")
    
    if [ "$manifest_file_id" = "$file_id" ] && [ -f "$MOD_DIR/$file_name" ]; then
        printf "${DIM}%s${NC} ${GREEN}(up-to-date)${NC}\n" "$mod_name"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi
    
    # Remove old version if updating
    [ -n "$manifest_filename" ] && [ -f "$MOD_DIR/$manifest_filename" ] && rm -f "$MOD_DIR/$manifest_filename"
    
    # Build download URL and fetch
    formatted_id=$(format_file_id "$file_id")
    download_url="${FORGECDN_URL}/${formatted_id}/${file_name}"
    
    printf "${CYAN}%s${NC} " "$mod_name"
    if download_file "$download_url" "$MOD_DIR/$file_name"; then
        update_manifest "$mod_id" "$file_id" "$file_name" "$mod_name"
        printf "${GREEN}(downloaded)${NC}\n"
        DOWNLOAD_COUNT=$((DOWNLOAD_COUNT + 1))
    else
        printf "${RED}(download failed)${NC}\n"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

# --- Cleanup orphaned mods ---

log_step "Cleanup"
REMOVED_COUNT=0

manifest_mods=$(jq -r '.mods | keys[]' "$MANIFEST_FILE" 2>/dev/null) || true

for manifest_mod_id in $manifest_mods; do
    [ -z "$manifest_mod_id" ] && continue
    
    # Check if mod is still in current list
    case " $CURRENT_MODS " in
        *" $manifest_mod_id "*) continue ;;
    esac
    
    # Remove orphaned mod
    old_filename=$(get_from_manifest "$manifest_mod_id" "fileName")
    if [ -n "$old_filename" ] && [ -f "$MOD_DIR/$old_filename" ]; then
        rm -f "$MOD_DIR/$old_filename"
        printf "      ${DIM}↳ Removed:${NC} ${YELLOW}%s${NC}\n" "$old_filename"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
    remove_from_manifest "$manifest_mod_id"
done

[ "$REMOVED_COUNT" -eq 0 ] && printf "${DIM}no orphaned mods${NC}\n"

# --- Summary ---

log_step "Summary"
printf "${GREEN}%d downloaded${NC}, ${DIM}%d up-to-date${NC}" "$DOWNLOAD_COUNT" "$SKIP_COUNT"
[ "$ERROR_COUNT" -gt 0 ] && printf ", ${RED}%d errors${NC}" "$ERROR_COUNT"
[ "$REMOVED_COUNT" -gt 0 ] && printf ", ${YELLOW}%d removed${NC}" "$REMOVED_COUNT"
printf "\n"
