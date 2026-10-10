# Angry Birds LÖVE2D

An accurate *work-in-progress* port of Angry Birds' proprietary engine (Ka3D/Fusion) to [LÖVE](https://love2d.org/) (the free 2D game framework that uses Lua). This is not a game version nor a decompilation, but an engine reimplementation/port. No games are bundled by default, but many versions (Classic, Seasons, and many of their platform releases) are supported.

> [!Note]
> Angry Birds LÖVE2D is currently not feature-complete with the original engine, making it less suitable for modding. In its current state, it is more tailored to people curious about the engine and its inner workings. By all means, you're allowed to use it for modding, but please be wary of potential discrepancies.

## Installation
First, make sure you have [LÖVE](https://love2d.org/) installed, as it is obviously required to run this project. The latest [LÖVE 12 nightly release](https://nightly.link/love2d/love/workflows/main/main) is recommended for its new features, but not required (unless something breaks by accident).

### Windows
It is highly recommended to test from the source code instead of the last release, as it is severely outdated.

Open the green Code dropdown, and download and extract the .zip file. On Windows, find and copy lovec.exe (or love.exe) to the unzipped folder (on a full installation this is located in C:\Program Files\LOVE\). Finally, drag and drop main.lua to the LÖVE executable (this only works on LOVE 12, you'll probably have to open a command prompt in earlier versions).

Now, you should be on a white screen; this means no game is loaded. You can either add a game folder to `data/`, or open the file manager and right-click/long-press a folder or file to run it.

### Linux
Running on Linux is as easy as downloading LÖVE from Flathub or another source, navigating to the project folder (again, use the latest source code), and running `love .` in a terminal.

### Android
It's not as simple to run on Android at the moment. First, install love-android.apk from the latest [LÖVE 12 (Android) nightly release](https://nightly.link/love2d/love-android/workflows/main/main). With a file manager that can access `Android/data`, navigate to `Android/data/org.love2d.android/files/games` and create a folder with whatever name you want. Here, you will extract the contents of the source code .zip file (main.lua must be in the root of the folder). Finally, you can open LOVE and launch the game from there.

Remember to download libcrypto.so through the file manager's long-click dropdown, or encrypted game files will not load.

This has only been tested on Windows (64-bit and ARM64), Linux (64-bit), Android (64-bit), and iOS (using LOVE2D Studio). If you find that any platforms supported by LÖVE do not properly run AB-LÖVE2D on stable game versions (e.g. Classic 3.0.1), feel free to report an issue about it.

## Command line arguments
- `--datapath`/`-dp` overrides the default path to `data/` and uses a new save data subfolder. Useful for instantly booting into mods or app files. Can also be used to boot from .zip/.ipa/.apk or other zipped files. Example: `--datapath apks/2.2.0.apk`
- `--model`/`-m` overrides the `deviceModel`. Useful for setting your own if it isn't auto-detected.
- `--skipintro`/`-si` automatically skips the game's splash screen on certain older versions.
- `--run`/`+..."` runs a line of Lua code before starting the game. Examples: `--run "gamelua.releaseBuild = true"` `+"autoScale = 240"`
- `--deletedata`/`-dd` prompts to delete save data (settings.lua and highscores.lua).
- `--cheats`/`-c` enables cheats. (Enabled `cheatsEnabled`, overrides options.lua)
- `--nosave`/`-ns` disables saving any Lua files (i.e., settings, highscores, and other files will not save).

## Keybinds
Some useful debug keybinds have been added:

- `Shift+D`/click bottom right corner: Brings up a console that lets you run Lua code on the fly. It also presents a scrollable print log and a link to the file manager.
- `Shift+A`: Speeds up the game by 5x.
- `Shift+Z`: Toggles a complete pause of the game. Press `A` to step one frame or `Shift+A` to step five frames.

## Variables
Here are some variables that can be changed by the debug console:

- `timeScale`: Defaults to 1, modifies the speed of the game.
- `audioSpeed`: Defaults to 1, modifies the audio pitch and speed.
- `accurateAudioSpeed.on`: Defaults to false, controls if the game should try to emulate a forced sample rate for all sound effects.
- `autoScale`: Defaults to 0, scales the display of the game depending on a target screen height. Has no effect at 0.
- `displayScale`: Defaults to 1, scales the whole display of the game. Controlled by `autoScale` if it's not 0.

## Dependencies
These projects can be added to support more versions:

The libcrypto library, a part of [OpenSSL](https://github.com/openssl/openssl), is used to decrypt encrypted Lua files.
- On Windows, you must get libcrypto-3.dll to use it: https://slproweb.com/products/Win32OpenSSL.html

[LZMA](https://www.7-zip.org/sdk.html) is used to extract Lua files compressed with LZMA.
- On Windows, you must get lzma.exe (found in bin/x64/lzma.exe) to use it.

## Acknowledgments
These projects are included within the engine:

[lua-bit-numberlua](https://github.com/davidm/lua-bit-numberlua) is used as a replacement for LuaJIT's bit library if it's not present.

[json.lua](https://github.com/rxi/json.lua) is used to parse JSON files from later game versions.

[fetch-lua](https://github.com/elloramir/fetch-lua) is used to download cloud assets from later game versions.

This project is maintained by romoney5 and Halo345. It is not affiliated with or endorsed by Rovio Entertainment Corporation.
