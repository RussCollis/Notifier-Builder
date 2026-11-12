# Notifier Builder

[![Buy me a coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=russcollis&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff)](https://www.buymeacoffee.com/russcollis)

<img src="Notifier%20Builder/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" alt="Notifier Builder icon">

A macOS app for designing, previewing and generating commands for Jamf Notifier notifications.

**Version:** 1.1
**Owner:** Russell Collis

## Features

- **Live preview:** see how your alert or banner will look on a macOS desktop as you edit it.
- **Notification options:** set the type (persistent alert or temporary banner), title, subtitle, message, sound and remove behaviour (`--remove prior` / `--remove all`).
- **Templates:** start from documentation examples or enterprise MDM presets.
- **Code inspector:** generates the matching Notifier command line, and can parse a pasted command back into the editor.
- **Live test:** post a real macOS system notification, or run the installed Jamf Notifier binary with your settings.
- **Sound audition:** preview the selected macOS system sound.

## Install

Download `NotifierBuilder-1.1.pkg` from this repo and open it. It installs **Notifier Builder.app** into `/Applications`.

## Build from source

Requires Xcode. To build the app and an installer package:

```bash
./build_installer.sh
```

This builds the Release configuration and writes `NotifierBuilder-<version>.pkg` next to the script.
