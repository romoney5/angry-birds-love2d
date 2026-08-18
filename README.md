# Angry Birds LÖVE2D

An accurate *work-in-progress* port of Angry Birds' proprietary engine (Ka3D/Fusion) to [LÖVE](https://love2d.org/) (the free 2D game framework that uses Lua). This is not a game version nor a decompilation, but an engine reimplementation/port. No games are bundled by default, but many versions (Classic, Seasons, and many of their platform releases) are supported.

To download, first make sure you have [LÖVE](https://love2d.org/) installed, as it is required to run this project. The latest [LÖVE 12 nightly release](https://nightly.link/love2d/love/workflows/main/main) is recommended, but not required (unless something breaks by accident).

It is highly recommended to test from the source code instead of the last release, as it is severely outdated. Open the green Code dropdown, and download and extract the .zip file. On Windows, go to C:\Program Files\LOVE\ and copy lovec.exe (or love.exe) to the unzipped folder. Finally, drag and drop main.lua to the LÖVE executable.

If you are on Linux, it's as easy as downloading a LÖVE Flatpak, navigating to the project folder, and running `love .` in a terminal.

Now, you should be on a white screen; this means no game is loaded. You can either add a game folder to `data/` or open the file manager (Shift+D for the debug console, then press Files from there), and right-click a folder or file to be able to run it.

> [!Note]
> Angry Birds LÖVE2D is currently not intended to be used for modding; rather for people curious about the engine and its inner workings. By all means you're allowed to use it for modding, but please note it still has discrepancies with the original engine.

This has only been tested on Windows (64-bit and ARM64), Linux (64-bit), Android (64-bit), and iOS (using LOVE2D Studio). If you find that any platforms supported by LÖVE do not properly run AB-LÖVE2D on stable game versions (e.g. Classic 3.0.1), feel free to report an issue about it.

## Command line arguments
- `--datapath`/`-dp` overrides the default path to `data/` and uses a new save data subfolder. Useful for playing mods or from app files. Can also be used to boot from .zip/.ipa/.apk or other zipped files. Example: `--datapath 2.2.0.apk`
- `--model`/`-m` overrides the `deviceModel`. Handy for testing for other devices, such as Android or Roku.
- `--skipintro`/`-si` automatically skips the game's splash screen.
- `--run`/`+..."` runs a line of Lua code before starting the game. Examples: `--run "releaseBuild = true"` `+"autoScale = 240"`
- `--deletedata`/`-dd` prompts to delete save data (settings.lua and highscores.lua).
- `--cheats`/`-c` enables cheats. (Enabled `cheatsEnabled`, overrides options.lua)
- `--blamelength`/`-bl` sets the length of bytecode tracebacks (a list of previously run instructions shown upon getting an error; very useful for debugging compiled Luas). Set to 0 by default for performance reasons.
- `--nosave`/`-ns` disables saving any Lua files (e.g. settings and highscores will not save).

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
These projects can be added to support more versions:

The libcrypto library, a part of [OpenSSL](https://github.com/openssl/openssl), is used to decrypt encrypted Lua files.
- On Windows, you must get libcrypto-3.dll to use it: https://slproweb.com/products/Win32OpenSSL.html

[LZMA](https://www.7-zip.org/sdk.html) is used to extract Lua files compressed with LZMA.
- On Windows, you must get lzma.exe (found in bin/x64/lzma.exe) to use it.

## Acknowledgments
These projects are included within the engine:

[FiOne](https://github.com/Rerumu/FiOne) (with some edits) is used to run compiled Lua files.
- May be replaced soon as it's licensed under the GPL (I aim to license this under the MIT license) and uses a lot of memory (the garbage collector runs very often and slows the game down).

[love-webp](https://github.com/ImagicTheCat/love-webp) is used to read WebP images.

[lua-bit-numberlua](https://github.com/davidm/lua-bit-numberlua) is used as a replacement for LuaJIT's bit library if it's not present.

This project is maintained by romoney5 and Halo345. It is not affiliated with or endorsed by Rovio Entertainment Corporation.
