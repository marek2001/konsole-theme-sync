#!/bin/bash

# ==============================================================================
# KONSOLE THEME SYNC
#
# Description: Automatically switches KDE Konsole profiles based on the system
#              color scheme (Light/Dark) in real-time.
# Dependencies: inotify-tools, qdbus, kwriteconfig6 (or 5)
# ==============================================================================

# --- CONFIGURATION ---
# Define the exact names of your Konsole profiles here.
# These must match the profile names found in Konsole settings.
LIGHT_PROFILE="Light"   # Profile to use when system is in Light mode
DARK_PROFILE="Dark"     # Profile to use when system is in Dark mode

# Path to the KDE global configuration file
CONFIG_FILE="$HOME/.config/kdeglobals"

# --- FUNCTIONS ---

# Logs messages with a timestamp for debugging purposes
log_message() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Updates the Konsole profile for both new and running sessions
change_konsole_profile() {
    NEW_PROFILE=$1
    log_message "Change detected. Setting Konsole profile to: $NEW_PROFILE"

    # 1. Update the default profile for NEW tabs/windows.
    # We prefer kwriteconfig6 if available, otherwise fallback to sed.
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$NEW_PROFILE.profile"
    else
        # Direct file manipulation as a fallback for older systems
        sed -i "s/^DefaultProfile=.*/DefaultProfile=$NEW_PROFILE.profile/" ~/.config/konsolerc
    fi

    # 2. Update ALREADY OPEN windows using D-Bus.
    # This iterates through all running Konsole services and sessions.
    konsole_services=$(qdbus | grep org.kde.konsole)
    for service in $konsole_services; do
        sessions=$(qdbus "$service" | grep -E '^/Sessions/')
        for session in $sessions; do
            qdbus "$service" "$session" org.kde.konsole.Session.setProfile "$NEW_PROFILE"
        done
    done
}

# Reads the current system color scheme and triggers the profile switch
check_system_theme() {
    # Attempt to read the ColorScheme from kdeglobals
    if command -v kreadconfig6 &> /dev/null; then
        CURRENT_THEME=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
    else
        CURRENT_THEME=$(kreadconfig5 --file kdeglobals --group General --key ColorScheme)
    fi

    # Trim leading/trailing whitespace
    CURRENT_THEME=$(echo "$CURRENT_THEME" | xargs)

    log_message "Current system theme: '$CURRENT_THEME'"

    # Match the theme name against known dark theme keywords
    case "$CURRENT_THEME" in
        *Dark*|*dark*|*Dracula*|*Black*|*Night*)
            change_konsole_profile "$DARK_PROFILE"
            ;;
        *)
            # Default to light profile for any other theme name
            change_konsole_profile "$LIGHT_PROFILE"
            ;;
    esac
}

# --- MAIN EXECUTION ---

# Check if inotifywait is installed before starting
if ! command -v inotifywait &> /dev/null; then
    echo "Error: 'inotify-tools' is not installed. Please install it to use this script."
    exit 1
fi

log_message "Starting monitoring..."

# Perform an initial check immediately upon startup to sync state
check_system_theme

# Infinite loop to monitor file changes
while true; do
    # Wait for specific file events on the config file:
    # - close_write: file was written to and closed
    # - moved_to: file was moved/renamed (common in atomic saves)
    # - create: file was re-created
    inotifywait -q -e close_write -e moved_to -e create "$CONFIG_FILE"

    # Small delay to ensure the file write is fully complete before reading
    sleep 0.5
    
    # Re-evaluate the theme
    check_system_theme
done
