# Angry Birds LÖVE2D

An accurate work-in-progress port of Angry Birds' proprietary engine to LÖVE (the free game framework that uses Lua). Currently, Classic PC version 1.6.3.1 is bundled by default, but many other versions (Classic, Seasons, and their platform variants) work well.

To download, first make sure you have [LÖVE](https://love2d.org/) installed, as it is required to run this project. Head to [the latest release](https://github.com/romoney5/angry-birds-love2d/releases/latest) and get `angrybirds_love2d.love`. You can simply double-click the .love file to play.

You can also test from the source code without a .love file. This is more preferred as the last release is over a year old. Open the green Code dropdown, and download and extract the .zip file. On Windows, go to C:\Program Files\LOVE\ and copy lovec.exe (or love.exe) to the unzipped folder. Finally, drag and drop main.lua to the LÖVE executable.

If you are on Linux, it's as easy as downloading a LÖVE Flatpak, navigating to the project folder, and running `love .` in a terminal.

## Command line arguments
- `--datapath`/`-dp` overrides the default path to `data/` and uses a new save data subfolder. Useful for playing mods or from app files. Can also be used to boot from .zip/.ipa/.apk or other zipped files. Example: `--datapath 2.2.0.apk`
- `--model`/`-m` overrides the `deviceModel`. Handy for testing for other devices, such as Android or Roku.
- `--skipintro`/`-si` automatically skips the game's splash screen.
- `--run`/`+".."` runs a line of Lua code before starting the game. Examples: `--run "releaseBuild = true"` `+"autoScale = 240"`
- `--deletedata`/`-dd` prompts to delete save data (settings.lua and highscores.lua).
- `--cheats`/`-c` enables cheats. (Enabled `cheatsEnabled`, overrides options.lua)
- `--blamelength`/`-bl` sets the length of bytecode tracebacks (a list of previously run instructions shown upon getting an error; very useful for debugging compiled Luas). Set to 0 by default for performance reasons.
- `--nosave`/`-ns` disables saving any Lua files (settings and highscores will not save).

## Keybinds
Some debug keybinds have been added:

- `Shift+D`/click bottom right corner: Brings up a console that lets you run Lua code on the fly. It also presents a scrollable print log.
- `Shift+A`: Speeds up the game by 5 times.
- `Shift+Z`: Toggles a complete pause of the game. Press `A` to step one frame or `Shift+A` to step five frames.

## Variables
Here are some variables that can be changed by the debug console:

- `timeScale`: Defaults to 1, modifies the speed of the game.
- `audioSpeed`: Defaults to 1, modifies the audio pitch and speed.
- `accurateAudioSpeed.on`: Defaults to false, controls if the game should try to emulate a forced sample rate for all sound effects.
- `gravity.x`/`gravity.y`: Defaults to 0 and 20 respectively, controls the level's gravity.
- `autoScale`: Defaults to 0 (or 720 on Android), scales the display of the game depending on a target screen height. Has no effect if it's zero.
- `displayScale`: Defaults to 1, scales the whole display of the game. Controlled by `autoScale` if it's not zero.

## Dependencies
The libcrypto library, a part of [OpenSSL](https://github.com/openssl/openssl), is used to decrypt encrypted Lua files.
- You must get libcrypto-3.dll to use it: https://slproweb.com/products/Win32OpenSSL.html

[7-Zip](https://www.7-zip.org/) is used to extract Lua files compressed with 7z.
- You must get 7z.exe to use it.

[LZMA](https://www.7-zip.org/sdk.html) is used to extract Lua files compressed with LZMA.
- You must get lzma.exe (found in bin/x64/lzma.exe) to use it.

## Acknowledgments
[FiOne](https://github.com/Rerumu/FiOne) is used to run compiled Lua files (with some edits).

[love-webp](https://github.com/ImagicTheCat/love-webp) is used to read WebP images.

This port is not affiliated with or endorsed by Rovio Entertainment Corporation.
