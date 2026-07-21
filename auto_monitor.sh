#!/bin/bash

# ==============================================================================
# KDE SYSTEM THEME MONITOR SCRIPT (LIGHT/DARK)
# Features:
# 1. Changes Konsole application profile (Background, Fonts, Cursor).
# 2. Changes Fish shell syntax highlighting (Universal variables).
# ==============================================================================

LIGHT_PROFILE="Light"
DARK_PROFILE="Dark"
CONFIG_FILE="$HOME/.config/kdeglobals"

# Variable storing the last applied state to avoid redundancy
LAST_STATE=""

log_message() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# --- FISH FUNCTIONS ---
set_fish_light() {
    log_message "Fish: Applying LIGHT THEME colors..."
    fish -c "
        set -U fish_color_autosuggestion 6C664B
        set -U fish_color_cancel ffffff --background=000000
        set -U fish_color_command 036A96
        set -U fish_color_comment 6C664B
        set -U fish_color_cwd 00cd00
        set -U fish_color_cwd_root cd0000
        set -U fish_color_end A34D14
        set -U fish_color_error CB3A2A
        set -U fish_color_escape A3144D
        set -U fish_color_history_current --bold
        set -U fish_color_host 000000
        set -U fish_color_host_remote a0a000
        set -U fish_color_keyword A3144D
        set -U fish_color_match --background=CFCFDE
        set -U fish_color_normal 1F1F1F
        set -U fish_color_operator A34D14
        set -U fish_color_option FF9322
        set -U fish_color_param 644AC9
        set -U fish_color_quote FF79C6
        set -U fish_color_redirection 1F1F1F
        set -U fish_color_search_match --background=CFCFDE
        set -U fish_color_selection --background=CFCFDE
        set -U fish_color_status cd0000
        set -U fish_color_user 00cd00
        set -U fish_color_valid_path --underline=single
        set -U fish_pager_color_background
        set -U fish_pager_color_completion 1F1F1F
        set -U fish_pager_color_description 6C664B
        set -U fish_pager_color_prefix 036A96
        set -U fish_pager_color_progress 6C664B
        set -U fish_pager_color_secondary_background
        set -U fish_pager_color_secondary_completion
        set -U fish_pager_color_secondary_description
        set -U fish_pager_color_secondary_prefix
        set -U fish_pager_color_selected_background --background=CFCFDE
        set -U fish_pager_color_selected_completion 060606 --bold
        set -U fish_pager_color_selected_description 060606 --bold --italics
        set -U fish_pager_color_selected_prefix 060606 --bold
    "
}

set_fish_dark() {
    log_message "Fish: Applying DARK THEME colors..."
    fish -c "
        set -U fish_color_autosuggestion 6272a4
        set -U fish_color_cancel ff5555 --reverse
        set -U fish_color_command 8be9fd
        set -U fish_color_comment 6272a4
        set -U fish_color_cwd 50fa7b
        set -U fish_color_cwd_root red
        set -U fish_color_end ffb86c
        set -U fish_color_error ff5555
        set -U fish_color_escape ff79c6
        set -U fish_color_history_current --bold
        set -U fish_color_host bd93f9
        set -U fish_color_host_remote bd93f9
        set -U fish_color_keyword ff79c6
        set -U fish_color_match --background=BD93F9
        set -U fish_color_normal f8f8f2
        set -U fish_color_operator 50fa7b
        set -U fish_color_option ffb86c
        set -U fish_color_param bd93f9
        set -U fish_color_quote f1fa8c
        set -U fish_color_redirection f8f8f2
        set -U fish_color_search_match --background=44475a --bold
        set -U fish_color_selection --background=44475a --bold
        set -U fish_color_status ff5555
        set -U fish_color_user 8be9fd
        set -U fish_color_valid_path --underline
        set -U fish_pager_color_background FF79C6
        set -U fish_pager_color_completion f8f8f2
        set -U fish_pager_color_description 6272a4
        set -U fish_pager_color_prefix 6272A4 --bold --underline=single
        set -U fish_pager_color_progress 6272a4
        set -U fish_pager_color_secondary_background
        set -U fish_pager_color_secondary_completion f8f8f2
        set -U fish_pager_color_secondary_description 6272a4
        set -U fish_pager_color_secondary_prefix 8be9fd
        set -U fish_pager_color_selected_background --background=44475a
        set -U fish_pager_color_selected_completion f8f8f2
        set -U fish_pager_color_selected_description 6272a4
        set -U fish_pager_color_selected_prefix 6272A4
    "
}

# --- MAIN LOGIC ---
apply_theme() {
    THEME_MODE=$1

    # Verify if the change is necessary
    if [ "$THEME_MODE" == "$LAST_STATE" ]; then
        return 0
    fi
    LAST_STATE="$THEME_MODE"

    if [ "$THEME_MODE" == "dark" ]; then
        NEW_PROFILE="$DARK_PROFILE"
        set_fish_dark
    else
        NEW_PROFILE="$LIGHT_PROFILE"
        set_fish_light
    fi

    log_message "Konsole: Changing profile to: $NEW_PROFILE"

    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$NEW_PROFILE.profile"
    else
        sed -i "s/^DefaultProfile=.*/DefaultProfile=$NEW_PROFILE.profile/" ~/.config/konsolerc
    fi

    # Automatic detection of the appropriate qdbus command
    QDBUS_CMD=""
    if command -v qdbus6 &>/dev/null; then
        QDBUS_CMD="qdbus6"
    elif command -v qdbus-qt6 &>/dev/null; then
        QDBUS_CMD="qdbus-qt6"
    elif command -v qdbus &>/dev/null; then
        QDBUS_CMD="qdbus"
    fi

    # Apply the profile in current Konsole sessions (if qdbus is available)
    if [ -n "$QDBUS_CMD" ]; then
        for service in $($QDBUS_CMD | grep org.kde.konsole); do
            for session in $($QDBUS_CMD "$service" | grep -E '^/Sessions/'); do
                $QDBUS_CMD "$service" "$session" org.kde.konsole.Session.setProfile "$NEW_PROFILE" &
            done
        done
    else
        log_message "Warning: qdbus command not found. Open Konsole windows may not refresh immediately."
    fi
}

# --- SYSTEM THEME DETECTION ---
check_system_theme() {
    if command -v kreadconfig6 &>/dev/null; then
        CURRENT_THEME=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
    else
        CURRENT_THEME=$(kreadconfig5 --file kdeglobals --group General --key ColorScheme)
    fi

    CURRENT_THEME=$(echo "$CURRENT_THEME" | xargs)

    case "$CURRENT_THEME" in
        *Dark* | *dark* | *Dracula* | *Black* | *Night*)
            apply_theme "dark"
            ;;
        *)
            apply_theme "light"
            ;;
    esac
}

# --- LISTENING LOOP (DAEMON) ---
log_message "### STARTING MONITOR ###"
check_system_theme # First run on script startup

# We use a while true loop because KDE uses "atomic saves"
# (it replaces the kdeglobals file, removing the old inode). 
# The loop allows hooking into the newly created file every time.
while true; do
    inotifywait -q "$CONFIG_FILE"

    # A short delay prevents read errors when the file is being replaced
    sleep 0.5
    check_system_theme
done
