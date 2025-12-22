This is a Swift application that runs in a terminal, named "HyperTile". It's intention is to be a fast and opinionated tiling window manager.

## Inputs and general rules

- The application will listen globally for user keyboard inputs.
- The application will be optomized for speed where possible, if we need to store state in local memory to improve speed then we will do that rather than calculate on demand.
- The keyboard inputs will always be "hyper+letter/number".
- "Hyper" is defined as "ctrl+cmd+shift+opt held simultaneously.
- example: hyper+a or hyper+4 would be valid inputs
- app window movements will always be on the primary screen, this app does not support secondary screen.
- There will be no spacing gaps between windows and the edges of the screen nor between windows and other windows when in half/half position.
- The focused app will have a 2px cyan border around it. When the focused app position changes the border will move with it.

## Definitions and clarifications.

- Full Screen is considered to be an app window that touches the left, right, bottom and top (touching menubar) - this is not "Apple" full screen.
- If an app centered setting is 80 that means the gap between the window and the left side of the screen is 10% and same on the right.
- If a mouse position is 50,50 that means the mouse is centered on the window
- If a mouse position is 100,50 that means it's centered on the right edge of the window frame

## State Management

- Application state should store it's previous position AND it's previous half side position. Since Full Screen toggle will need to know previous and swap will need to know which was the last side occupied.
- Application state should always know the centered coordinates of each app binding
- Whatever else is useful to make the app faster

## Configuration Schema

### There will be a JSON configuration file stored in ~/.config/hypertile.config.json . The config file will have the following 4 things:

- swap: hyper+7
- full: hyper+g
- defaultCenteredWidth: 75 (default value 75) (this can be overridden per app)
- a list of App bindings with the following properties:
  {
  appName: "NAME_OF_APPLICATION" (example: "iTerm" or "Microsoft Teams" or "Google Chrome")
  bind: (alphanumeric char) -- a single alphanumeric character, the binding will be hyper+char
  mousePosition?: x (0-100), y (0-100) -- expressed as percentage. 0, 0 is top left corner, 100,100 is bottom right corner
  centeredWidth?: (40-90) (default to empty) -- a percentage of how much of the horizontal space the application will occupy.
  }

### Default Conifg:

the following are default applicaiton bindings to include in the default config. These are specified as CSV for shorthand (appName, bind, mouseX, mouseY)

- iTerm, d, 90, 50
- neovide, f, 90, 50
- Google Chrome, e, 50, 50
- Safari, r, 50, 50
- Microsoft Teams, c, 60, 50
- Microsoft Outlook, v, 50, 50

## Application Behavior

The following are the 3 core functions of the application:

### When an App binding is pressed:

- If the application is not open, do not open it, just print a warning, skip further instructions.
- The app that is currently active, if centered or full screen, return that application to it's most recently occurpied half screen location (reference the "swap" button instructions for additional clarity on this instruction)
- Bring the App that is associated with the App binding to an active and focused state, move the mouse cursor to the position in the window specified by the config.
- If the App who's app binding was pressed is already active then move the app to it's "centered" position
- If the App is already centered then return it to it's most recently occupied half screen position (left or right)
- Whenever the application changes position always move the mouse cursor to the X,Y position within it's new window frame.
- Whenever the application changes position move the cyan border with it.

### When the Swap binding is pressed:

- If the application is occupying the left half of the screen then move it to the right half of the screen. The right half is now that app's default side.
- If the application is occupying the right half of the screen then move it to the left half of the screen. The left half is now that app's default side.
- If the application is currently centered or full return it to half screen on the side opposite of where it last occupied a half screen position
- Whenever an app window moves to a half screen position write that side, left or right, to state for that application as it's last know half side position.
- Whenever the application changes position always move the mouse cursor to the X,Y position within it's new window frame.
- Whenever the application changes position move the cyan border with it.

### When the Full binding is pressed:

- If the active application is already full screen return it to it's previously occupied position, centered, left or right
- Bring the active application window to full screen
- Whenever the application changes position always move the mouse cursor to the X,Y position within it's new window frame.
- Whenever the application changes position move the cyan border with it.
