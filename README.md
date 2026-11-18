<p align="center">
  <img src="Resources/logo.svg" width="128" alt="Switch logo">
</p>

<h1 align="center">Switch</h1>

<p align="center">
  Jump to any Mac app with <code>⌃</code> and a number. Press again for its next window.
</p>

Switch is a small menu bar app for macOS. You give each app a number, and `⌃` plus that number takes you there from anywhere. It replaces hunting through `⌘Tab` with a key you already know.

## Shortcuts

| Keys | What happens |
|---|---|
| `⌃` + number | Focus the app. If it isn't running, launch it. |
| Same keys again | Move to the app's next window. |
| Hold `⌃`, tap the number | Step through a list of the app's windows. |
| Release `⌃` | Focus the window selected in the list. |

Cycling covers fullscreen windows and windows on other Spaces.

## Install

1. Download `Switch.zip` from the [latest release](https://github.com/pranjalanimesh/switch-mac-app/releases/latest).
2. Unzip it and move `Switch.app` to Applications.
3. The build has no Apple developer signature, so macOS blocks the first launch. Clear the quarantine flag once:

   ```sh
   xattr -dr com.apple.quarantine /Applications/Switch.app
   ```

4. Open Switch.

Requires macOS 14 or later.

## Set up

1. Switch opens a window listing the apps you have open. Pick a number for each one you want a shortcut for. Number 3 means `⌃3`.
2. Click **Allow…** and turn Switch on under Privacy & Security → Accessibility. Switch uses this to list and raise windows. Without it the shortcuts still focus apps, but can't cycle windows.
3. Tick **Open at login** if you want it always running.

To bind an app that isn't open, use **Add App…**. To change numbers later, click the Switch icon in the menu bar and choose **Settings…**. A number belongs to one app at a time, so giving it to a second app takes it from the first.

## How it works

- **Hotkeys** are registered with Carbon's `RegisterEventHotKey`. They work in every app, need no permission, and the frontmost app never sees the keystroke.
- **Windows** come from the Accessibility API. The public window list skips other Spaces, so Switch also looks windows up by element ID, which finds fullscreen ones.
- **Settings** are a list of bundle IDs and numbers stored in `UserDefaults`.

The code is about 550 lines of Swift in `Sources/Switch`. `Switcher.swift` has the press, cycle and release logic.

## Build from source

You need the Swift toolchain from the Xcode Command Line Tools. Xcode itself is not required.

```sh
git clone https://github.com/pranjalanimesh/switch-mac-app.git
cd switch-mac-app
./build.sh run
```

This writes `build/Switch.app` and launches it. Each build gets a new ad-hoc signature, so macOS asks for Accessibility access again after every rebuild. If the old toggle looks on but Switch still asks, run `tccutil reset Accessibility dev.switch.Switch` and allow it again.

## Known gaps

- Window cycling finds no windows for a few apps, including Notes, Numbers and Spotify. The shortcut still focuses them.
- `⌃1` to `⌃9` clash with the "Switch to Desktop" shortcuts if you enabled those under Keyboard → Keyboard Shortcuts → Mission Control.
- The modifier is fixed to `⌃`, and there are ten numbers.
