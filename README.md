# Angry Birds LÖVE2D

An accurate *work-in-progress* port of Angry Birds' proprietary engine (Ka3D/Fusion) to [LÖVE](https://love2d.org/) (the free 2D game framework that uses Lua). This is not a decompilation, but an engine reimplementation/port. No games are bundled by default, but many versions (Classic, Seasons, and many of their platform releases) are supported.

> [!Note]
> Angry Birds LÖVE2D is currently not feature-complete with the original engine, making it less suitable for modding. In its current state, it is more tailored to people curious about the engine and its inner workings. By all means, you're allowed to use it for modding, but please be wary of potential discrepancies.

## Installation
First, make sure you have [LÖVE](https://love2d.org/) installed, as it is obviously required to run this project. The latest [LÖVE 12 nightly release](https://nightly.link/love2d/love/workflows/main/main) is recommended for its new features, but LÖVE 11.5 also works (unless something breaks by accident).

### Windows
It is highly recommended to test from the source code instead of the last release, as it is severely outdated.

First, download and extract the .zip file from the green Code dropdown. On Windows, find and copy lovec.exe or love.exe to the unzipped folder (on a full installation, the .exes are located in C:\Program Files\LOVE\). Finally, drag and drop main.lua to the LÖVE executable (this only works on LOVE 12, you may have to open a command prompt in earlier versions).

Now, you should be on a debug console; this means no game is loaded. You can either add a game folder named `data/`, or open the file manager (Files button) and right-click/long-press a folder or file to run it.

### Linux
Running on Linux is as easy as downloading LÖVE from Flathub or another source, navigating to the project folder (again, using the latest source code), and running `love .` in a terminal.

### Android
It's not as simple to run on Android at the moment. First, install love-android.apk from the latest [LÖVE 12 nightly release](https://nightly.link/love2d/love/workflows/main/main). As the GitHub Actions .apk is unsigned, you must resign it with your APK editor of choice before installing it. With a file manager that can access `Android/data`, navigate to `Android/data/org.love2d.android/files/games`. Here, you will extract the contents of the source code .zip file (`angry-birds-love2d-pc1.0.0` (or any other name) must be in the games folder, then main.lua). Finally, you can open LOVE and launch the game from there.

This has been tested on Windows (64-bit and ARM64), Linux (64-bit), Android (64-bit), and iOS (using LOVE2D Studio). If you find that any platforms supported by LÖVE do not properly run AB-LÖVE2D or have bugs on supported game versions (e.g. Classic 3.0.1), feel free to report an issue about it.

LuaJIT support is required for various features, e.g., reading AES-encrypted, LZMA-compressed, and PVRTC files.

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

## Acknowledgments
These projects are included within the engine:

[lua-bit-numberlua](https://github.com/davidm/lua-bit-numberlua) is used as a replacement for LuaJIT's bit library if it's not present.

[json.lua](https://github.com/rxi/json.lua) is used to parse JSON files from later game versions.

[fetch-lua](https://github.com/elloramir/fetch-lua) is used to download cloud assets from later game versions.

The [LZMA](https://www.7-zip.org/sdk.html) compression algorithm is used to extract Lua files compressed with LZMA.
- This project includes a translation of LzmaDec.c from LZMA SDK's C reference code to LuaJIT.
- An implementation of AES-256-CBC decryption is also included, translated from the LZMA SDK.

This project is maintained by romoney5 and Halo345. It is not affiliated with or endorsed by Rovio Entertainment Corporation.
