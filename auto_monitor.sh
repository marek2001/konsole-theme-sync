#!/bin/bash

# ==============================================================================
# KDE SYSTEM THEME MONITORING SCRIPT (LIGHT/DARK)
# Features:
# 1. Changes Konsole application profile (Background, Fonts, Cursor).
# 2. Changes Fish shell syntax highlighting (Universal variables).
# ==============================================================================

# --- USER CONFIGURATION ---
PROFIL_JASNY="Light"     # Konsole profile name for light mode
PROFIL_CIEMNY="Dark"     # Konsole profile name for dark mode

PLIK_CONFIG="$HOME/.config/kdeglobals"

# --- HELPER FUNCTIONS ---

loguj() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# --- FISH COLOR CONFIGURATION (SYNTAX HIGHLIGHTING) ---

ustaw_fish_jasny() {
    loguj "Fish: Applying LIGHT MODE colors (Alucard + Custom Pager)..."

    # Manual color setup for light mode.
    # Overwriting default colors to be readable on cream background.
    # fish_pager_* -> selection menu colors (tab completion).
    # fish_color_* -> syntax colors (commands, errors, params).

    fish -c "set -U fish_pager_color_selected_background --background=644AC9; set -U fish_pager_color_selected_description CFCFDE; set -U fish_color_normal 1F1F1F; set -U fish_color_autosuggestion 6C664B; set -U fish_color_command 036A96; set -U fish_color_param 644AC9; set -U fish_color_quote 846E15; set -U fish_color_error CB3A2A; set -U fish_color_comment 644AC9; set -U fish_pager_color_description 6C664B; set -U fish_pager_color_prefix 036A96; set -U fish_pager_color_completion 1F1F1F; set -U fish_color_option A34D14; set -U fish_color_redirection 1F1F1F"
}

ustaw_fish_ciemny() {
    loguj "Fish: Applying DARK MODE colors (Dracula Manual)..."

    # Manual restoration of Dracula palette.
    # Defining each variable separately to ensure all settings
    # from light mode are overwritten (including pager backgrounds and text colors).

    fish -c "
        set -U fish_color_normal f8f8f2;
        set -U fish_color_command 8be9fd;
        set -U fish_color_keyword ff79c6;
        set -U fish_color_quote f1fa8c;
        set -U fish_color_redirection f8f8f2;
        set -U fish_color_end ffb86c;
        set -U fish_color_error ff5555;
        set -U fish_color_param bd93f9;
        set -U fish_color_comment 6272a4;
        set -U fish_color_selection --bold --background=44475a;
        set -U fish_color_search_match --bold --background=44475a;
        set -U fish_color_operator 50fa7b;
        set -U fish_color_escape ff79c6;
        set -U fish_color_cwd 50fa7b;
        set -U fish_color_cwd_root red;
        set -U fish_color_option ffb86c;
        set -U fish_color_valid_path --underline=single;
        set -U fish_color_autosuggestion 6272a4;
        set -U fish_color_user 8be9fd;
        set -U fish_color_host bd93f9;
        set -U fish_color_host_remote bd93f9;
        set -U fish_color_status ff5555;
        set -U fish_color_cancel ff5555 --reverse;
        set -U fish_pager_color_prefix 8be9fd;
        set -U fish_pager_color_progress 6272a4;
        set -U fish_pager_color_completion f8f8f2;
        set -U fish_pager_color_description 6272a4;
        set -U fish_pager_color_selected_background --background=44475a;
        set -U fish_pager_color_selected_prefix 8be9fd;
        set -U fish_pager_color_selected_completion f8f8f2;
        set -U fish_pager_color_selected_description 6272a4;
        # Resetting the variables below to empty (default) to remove light mode backgrounds
        set -U fish_pager_color_background;
        set -U fish_pager_color_secondary_prefix;
        set -U fish_pager_color_secondary_description;
        set -U fish_pager_color_secondary_completion;
        set -U fish_pager_color_secondary_background;
        set -U fish_color_history_current --bold
    "
}

# --- MAIN CHANGE LOGIC ---

zmien_wszystko() {
    TRYB=$1

    if [ "$TRYB" == "dark" ]; then
        NOWY_PROFIL="$PROFIL_CIEMNY"
        ustaw_fish_ciemny
    else
        NOWY_PROFIL="$PROFIL_JASNY"
        ustaw_fish_jasny
    fi

    loguj "Konsole: Changing profile to: $NOWY_PROFIL"

    # 1. Changing default profile in config file (for new tabs/windows)
    # Checking availability of KDE tools (Plasma 6 or 5)
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$NOWY_PROFIL.profile"
    else
        sed -i "s/^DefaultProfile=.*/DefaultProfile=$NOWY_PROFIL.profile/" ~/.config/konsolerc
    fi

    # 2. Applying profile in all current sessions (open windows)
    uslugi_konsole=$(qdbus | grep org.kde.konsole)
    for usluga in $uslugi_konsole; do
        sesje=$(qdbus "$usluga" | grep -E '^/Sessions/')
        for sesja in $sesje; do
            # Calling D-Bus method to change profile on the fly
            qdbus "$usluga" "$sesja" org.kde.konsole.Session.setProfile "$NOWY_PROFIL"
        done
    done
}

# --- SYSTEM THEME DETECTION ---

sprawdz_motyw_systemu() {
    # Fetching current color scheme name from KDE settings
    if command -v kreadconfig6 &> /dev/null; then
        OBECNY_MOTYW=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
    else
        OBECNY_MOTYW=$(kreadconfig5 --file kdeglobals --group General --key ColorScheme)
    fi

    # Removing whitespace
    OBECNY_MOTYW=$(echo "$OBECNY_MOTYW" | xargs)

    loguj "System: Detected theme '$OBECNY_MOTYW'"

    # Decision based on theme name
    case "$OBECNY_MOTYW" in
        *Dark*|*dark*|*Dracula*|*Black*|*Night*)
            zmien_wszystko "dark"
            ;;
        *)
            zmien_wszystko "light"
            ;;
    esac
}

# --- LISTENING LOOP (DAEMON) ---

loguj "### MONITOR START ###"
sprawdz_motyw_systemu # First run at script startup

while true; do
    # inotifywait waits for write event in kdeglobals file
    # Using -e close_write, moved_to, create to handle various KDE write methods
    inotifywait -q -e close_write -e moved_to -e create "$PLIK_CONFIG"

    # Short delay to ensure file write is complete
    sleep 0.5
    sprawdz_motyw_systemu
done
