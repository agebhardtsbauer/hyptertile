# HyperTile

A fast and opinionated tiling window manager for macOS that runs in your terminal. HyperTile uses global keyboard shortcuts with the "Hyper" modifier key to quickly position and manage application windows.

## Features

- Global keyboard shortcuts using Hyper key (Ctrl + Cmd + Shift + Option)
- Fast window positioning: left half, right half, or centered
- Launch and focus applications with a single keystroke
- Optional mouse positioning within application windows
- JSON-based configuration
- Lightweight and runs in the background

## Installation

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools

### Build from Source

```bash
# Clone the repository
cd hypertile

# Build the application
swift build -c release

# Copy the binary to a location in your PATH
cp .build/release/hypertile /usr/local/bin/
```

## Setup

### 1. Grant Accessibility Permissions

HyperTile requires Accessibility permissions to monitor keyboard events and control windows.

1. Run HyperTile for the first time:
   ```bash
   hypertile
   ```

2. You'll be prompted to grant Accessibility permissions
3. Go to **System Settings** > **Privacy & Security** > **Accessibility**
4. Add Terminal (or your terminal app) to the list and enable it
5. Restart HyperTile

### 2. Configuration

On first run, HyperTile will create a default configuration file at:
```
~/.config/hypertile.config.json
```

You can customize this file to add your own application bindings.

### Configuration Schema

```json
{
  "main": "d",
  "alt": "s",
  "apps": [
    {
      "appName": "iTerm",
      "preferredSide": "left",
      "bind": "t",
      "mousePosition": null,
      "centered": 70
    }
  ]
}
```

#### Configuration Fields

- **main**: The key for the main toggle (default: "d")
  - Press Hyper + main to toggle between preferred side and centered

- **alt**: The key for the alternate toggle (default: "s")
  - Press Hyper + alt to toggle between opposite side and hidden

- **apps**: Array of application bindings, each with:
  - **appName**: Exact name of the application (as shown in the menu bar)
  - **preferredSide**: "left" or "right" - which side the app prefers
  - **bind**: Single alphanumeric character for the Hyper + key binding
  - **mousePosition** (optional): Object with x and y (0-100 percentages)
    - `{ "x": 50, "y": 50 }` centers the mouse in the window
    - `null` or omitted means don't move the mouse
  - **centered** (optional): Percentage of horizontal space when centered (50-90, default: 70)

## Usage

### Hyper Key

The "Hyper" modifier is defined as all four modifier keys pressed simultaneously:
- **Ctrl + Cmd + Shift + Option**

### Keyboard Shortcuts

#### Application Bindings (Hyper + letter/number)

When you press an app binding (e.g., Hyper + t for iTerm):
1. The application is brought into focus
2. If not running, the application is launched
3. If a mouse position is configured, the cursor moves to that position in the window

#### Main Toggle (Hyper + d, by default)

Toggles the focused application between:
- **Preferred side**: Left or right half of the screen
- **Centered**: Centered position with configurable width (default 70%)

Window positioning:
- Half screen: 10px borders on top, bottom, and the relevant side
- Centered: Configurable width with equal gaps on left and right

#### Alt Toggle (Hyper + s, by default)

Toggles the focused application between:
- **Opposite side**: The opposite of the preferred side
- **Hidden**: Hides the application

Behavior:
- If on opposite side → hide the app
- If hidden → unhide and show the app
- Otherwise → move to opposite side

## Example Workflow

With the default configuration:

1. **Hyper + t**: Open/focus iTerm on the left half
2. **Hyper + c**: Open/focus Chrome on the right half
3. **Hyper + d**: (while iTerm is focused) Toggle iTerm between left and centered
4. **Hyper + s**: (while iTerm is focused) Move iTerm to right or hide it

## Running on Startup

To run HyperTile automatically on startup:

### Using launchd

1. Create a launch agent plist file at `~/Library/LaunchAgents/com.hypertile.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hypertile</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/hypertile</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/hypertile.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hypertile.err</string>
</dict>
</plist>
```

2. Load the launch agent:
```bash
launchctl load ~/Library/LaunchAgents/com.hypertile.plist
```

3. To unload:
```bash
launchctl unload ~/Library/LaunchAgents/com.hypertile.plist
```

## Troubleshooting

### Application not launching

- Verify the exact application name matches what's shown in the menu bar
- Some apps have different internal names (e.g., "Microsoft Teams" vs "Teams")
- Check the console output for error messages

### Keyboard shortcuts not working

- Ensure Accessibility permissions are granted
- Verify your terminal app is in the Accessibility list
- Check that your key bindings don't conflict with system shortcuts
- Try restarting HyperTile

### Window positioning issues

- HyperTile uses the primary screen's visible frame
- Some apps may override window positioning
- Try adjusting the border values if windows appear cut off

## Advanced Configuration

### Multiple Displays

HyperTile currently works with the primary display. Window movements are relative to the screen the application currently occupies.

### Custom Border Sizes

To modify border sizes, edit the constants in `Sources/WindowManager.swift`:
```swift
private let border: CGFloat = 10
private let menuBarHeight: CGFloat = 25
private let dockHeight: CGFloat = 70
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is provided as-is for personal and educational use.
