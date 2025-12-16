This is a Swift application that runs in a terminal, named "HyperTile". It's intention is to be a fast and opinionated tiling window manager.

## Inputs and general rules

- The application will listen globally for user keyboard inputs.
- The application will be optomized for speed where possible, if we need to store state in local memory to improve speed then we will do that rather than calculate on demand.
- The keyboard inputs will always be "hyper+letter/number".
- "Hyper" is defined as "ctrl+cmd+shift+opt held simultaneously.
- example: hyper+a or hyper+4 would be valid inputs
- app window movements will always be on the primary screen, this app does not support secondary screen.

## Configuration Schema

### There will be a JSON configuration file stored in ~/.config/hypertile.config.json . The config file will have the following 4 things:

- left: hyper+d
- right: hyper+f
- defaultCenteredWidth: 75 (default value 75) (this can be overridden per app)
- a list of application bindings with the following properties:
  {
  appName: "NAME_OF_APPLICATION" (example: "iTerm" or "Microsoft Teams" or "Google Chrome")
  bind: (alphanumeric char) -- a single alphanumeric character, the binding will be hyper+char
  mousePosition?: x (0-100), y (0-100) -- expressed as percentage. 0, 0 is top left corner, 100,100 is bottom right corner
  centeredWidth?: (40-90) (default to empty) -- a percentage of how much of the horizontal space the application will occupy.
  }

#### Default Conifg:

the following are default applicaiton bindings to include in the default config. These are specified as CSV for shorthand (appName, bind, mouseX, mouseY)

- iTerm, 6, 50, 80
- neovide, 7, 50, 80
- Google Chrome, q, 50, 50
- Safari, a, 50, 50
- Microsoft Teams, w, 50, 60
- Microsoft Outlook, e, 50, 50

## Application Behavior

The following are the 3 core functions of the application:

### When an APP binding is pressed, in order of priority:

- bring the application window associated with the pressed keybind into a focused state (like "open -a ..." in zsh)
- if a mouse position is specified teleport the mouse to that relative position in the app window. If it's useful to keep the current app boundaries in memory make sure to store them in state prior to this step.

### When the left key is pressed (disabled in lite mode):

- toggle the application between the left side and centered
- when on the left side the application window will occupy the left HALF of the screen with a 10 pixel boarder top, left and bottom
- when the application is centered it will move to the center of the screen and occupy a horizontal with of 75% (unless other number is specified in config) of the screen. So, for example, if an application occupies "75" then from left to right you will have a 12.5% empty gap, 75% application width, and a final 12.5% empty gap. The Top of the window will be 10 pixels from the menu bar and the bottom will be 10 pixels from the bottom of the screen.
- repeated presses of the left key will toggle the application between the left side and centered.

### When the right key is pressed (disabled in lite mode):

- toggle the application between the right side and and centered
- when on the right side the application window will occupy the right horizontal HALF of the screen with a 10 pixel boarder: 10 top, 10 right, 10 bottom.
- if the app is on the right then the next click of the right key will center it
- repeated presses will toggle the application between right and center
- if the application is on the left and the right key is pressed, move the application to the right side, and vice versa.
- the application will only move to center if it is already on the side of the key stroke being pressed. For example, the app will only be centered if the user clicks the left button while the app is ON the left.

## Release structure

- There should be two versions of this application
- First version enables all of the features
- The second mode disables any feature that requires accessibility permissions. The primary function in this mode is to bring app window to active and move the mouse to it.
