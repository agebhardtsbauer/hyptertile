# HyperTile

A fast and opinionated tiling window manager for macOS that runs in your terminal. HyperTile uses global keyboard shortcuts with the "Hyper" modifier key to quickly focus applications, position windows, and move the mouse.

## Features

- **Global keyboard shortcuts** using Hyper key (Ctrl + Cmd + Shift + Option)
- **Fast app switching** - bring any configured app to focus instantly
- **Automatic mouse positioning** - teleport mouse to specific window locations
- **Window tiling** - position windows left/right/center with precise control
- **JSON-based configuration** - easy to customize
- **Lightweight** - runs silently in the background

## Installation

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/hypertile
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
  "left": "d",
  "right": "f",
  "defaultCenteredWidth": 75,
  "apps": [
    {
      "appName": "iTerm2",
      "bind": "6",
      "mousePosition": {
        "x": 50,
        "y": 80
      },
      "centeredWidth": null
    },
    {
      "appName": "neovide",
      "bind": "7",
      "mousePosition": {
        "x": 50,
        "y": 80
      },
      "centeredWidth": null
    }
  ]
}
```

#### Configuration Fields

- **left**: The key for left/center window toggle (default: "d")
  - Press Hyper + left to toggle between left half and centered

- **right**: The key for right/center window toggle (default: "f")
  - Press Hyper + right to toggle between right half and centered

- **defaultCenteredWidth**: Default width percentage when centered (40-100, default: 75)

- **apps**: Array of application bindings, each with:
  - **appName**: Exact name of the application (as shown in the menu bar)
  - **bind**: Single alphanumeric character for the Hyper + key binding
  - **mousePosition** (optional): Object with x and y (0-100 percentages)
    - `{ "x": 50, "y": 80 }` positions mouse at 50% width, 80% height of window
    - `null` or omitted means don't move the mouse
  - **centeredWidth** (optional): Override default centered width for this app (40-100)

## Usage

### Hyper Key

The "Hyper" modifier is defined as all four modifier keys pressed simultaneously:
- **Ctrl + Cmd + Shift + Option**

**Tip:** Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to map Caps Lock to Hyper for easier access.

### Keyboard Shortcuts

#### Application Bindings (Hyper + letter/number)

When you press an app binding (e.g., Hyper + 6 for iTerm2):
1. **Brings the application into focus** (must already be running)
2. **Moves the mouse** to the configured position (if specified)

**Important:** HyperTile does NOT launch apps - the app must already be running. If the app is not running, you'll see a message in the terminal.

#### Window Tiling

**Hyper + d** (left toggle, by default):
- If window is on left → move to center
- Otherwise → move to left half

**Hyper + f** (right toggle, by default):
- If window is on right → move to center
- Otherwise → move to right half

**Window positioning:**
- **Left/Right half**: Takes up exactly 50% of screen width
- **Centered**: Configurable width (default 75%) with equal gaps on both sides

## Technical Details

### App Activation Methods

HyperTile uses a two-tier activation approach for maximum reliability:

1. **NSWorkspace.activate()** - Standard macOS API (fast, works for most apps)
2. **AppleScript activate** - System Events fallback (handles stubborn apps like Chrome, Safari, cross-platform apps like neovide)

This ensures apps are brought to focus reliably regardless of their implementation or current focus state.

### Accessibility Permissions

HyperTile requires Accessibility permissions for:
- **Global keyboard monitoring** - to listen for Hyper key combinations
- **Window manipulation** - to position and resize windows
- **Getting window information** - for state tracking and mouse positioning

Without these permissions, HyperTile cannot function.

## Example Workflow

With the default configuration:

1. **Hyper + 6**: Focus iTerm2 (mouse moves to 50%, 80%)
2. **Hyper + 7**: Focus neovide (mouse moves to 50%, 80%)
3. **Hyper + q**: Focus Chrome (mouse moves to 50%, 50%)
4. **Hyper + d** (while iTerm2 focused): Toggle iTerm2 between left and center
5. **Hyper + f** (while Chrome focused): Toggle Chrome between right and center

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

### "Application is not running" message

HyperTile does not launch apps - it only focuses already-running apps. Make sure the app is open before trying to focus it with Hyper + key.

### App doesn't come to focus

- **Verify app name**: Must match exactly what's shown in the menu bar
  - Some apps have different names (e.g., "iTerm2" not "iTerm")
  - Check menu bar while app is running to get exact name
- **Check terminal output**: HyperTile prints useful debug info
- The two-tier activation (NSWorkspace + AppleScript) handles most apps reliably

### Keyboard shortcuts not working

- Ensure Accessibility permissions are granted
- Verify your terminal app is in the Accessibility list
- Check that your key bindings don't conflict with system shortcuts
- Try restarting HyperTile

### Window positioning issues

- Some apps may override window positioning
- Try adjusting border sizes if windows appear cut off
- Ensure Accessibility permissions are granted

### Mouse not moving

- Verify Accessibility permissions are granted
- Check that `mousePosition` is configured in your app binding
- Verify coordinates are between 0-100

## Default Application Bindings

The default config includes these apps (customize as needed):

- **Hyper + 6** → iTerm2
- **Hyper + 7** → neovide
- **Hyper + q** → Google Chrome
- **Hyper + a** → Safari
- **Hyper + w** → Microsoft Teams
- **Hyper + e** → Microsoft Outlook

## Advanced Configuration

### Custom Border Sizes

To modify border sizes, edit `Sources/WindowManager.swift`:
```swift
private let border: CGFloat = 6
private let menuBarHeight: CGFloat = 25
```

Then rebuild:
```bash
swift build -c release
```

### Multiple Displays

HyperTile works with the primary display. Window movements use the visible frame of the main screen.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is provided as-is for personal and educational use.
