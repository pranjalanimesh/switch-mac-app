# Switch

<img src="Resources/logo.svg" width="96" alt="Switch logo">

A macOS menu bar app that gives each app a number. Press `⌃` and the number from anywhere to jump to that app. Press it again to move to the app's next window.

## Use

1. Open Switch. The settings window lists your open apps.
2. Pick a number for each app. Number 3 means `⌃3`.
3. Allow Accessibility access when asked. Switch needs it to list and raise windows, including fullscreen ones on other Spaces.

Keep `⌃` held while you press the number again and a list of the app's windows appears. Release `⌃` to focus the selected one.

If the app isn't running, the shortcut launches it.

## Install

Download `Switch.zip` from the latest release, unzip it and move `Switch.app` to Applications.

The build has no Apple developer signature, so macOS blocks the first launch. Clear the quarantine flag once:

```sh
xattr -dr com.apple.quarantine /Applications/Switch.app
```

## Build

Needs macOS 14 or later and the Swift toolchain. Xcode is not required.

```sh
./build.sh run
```

This writes `build/Switch.app` and launches it. Each build has a new ad-hoc signature, so macOS asks for Accessibility access again after a rebuild.

## Known gaps

- Window cycling finds no windows for a few apps, such as Notes, Numbers and Spotify. The shortcut still focuses them.
- `⌃1` to `⌃9` clash with the "Switch to Desktop" shortcuts if you turned those on in System Settings.
