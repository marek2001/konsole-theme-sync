# Konsole Theme Sync

**A lightweight Bash script that automatically switches [KDE Konsole](https://konsole.kde.org/) profiles based on your system-wide color scheme (Light/Dark).**

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square)
![KDE](https://img.shields.io/badge/Desktop-KDE_Plasma-1D99F3?style=flat-square)

## 📖 Overview

If you use a global theme switcher (like "Dracula" to "Breeze") in KDE Plasma, Konsole usually stays on its old color scheme unless manually changed. 

This script solves that by:
1.  **Monitoring** the KDE global config file for changes in real-time.
2.  **Switching** the default Konsole profile instantly when a Light/Dark change is detected.
3.  **Updating** all currently open Konsole windows and tabs using D-Bus.

Compatible with both **KDE Plasma 5** and **KDE Plasma 6**.

## ⚙️ Prerequisites

You need `inotify-tools` installed to monitor file system events.

**Arch Linux / Manjaro:**
```bash
sudo pacman -S inotify-tools
