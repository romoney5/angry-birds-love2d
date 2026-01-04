# Angry Birds on LÖVE

Accurate work-in-progress port of Angry Birds' engine to LÖVE. Currently, PC version 1.6.3.1 is targeted, but other versions may work with some fixes.

To download, first make sure you have [LÖVE](https://love2d.org/) installed, as it is required to run this project. Head to [the latest release](https://github.com/romoney5/angry-birds-love2d/releases/latest) and get `angrybirds_love2d.love`. You can simply double-click the .love file to play.

You can also test from the source code without a .love file. This is more preferred as the last release is over a year old. Open the green Code dropdown, and download and extract the .zip file. On Windows, go to C:\Program Files\LOVE\ and copy lovec.exe (or love.exe) to the unzipped folder. Finally, drag and drop main.lua to the LÖVE executable.

If you are on Linux, it's as easy as downloading a LÖVE Flatpak, navigating to the project folder, and running `love .` in a terminal.

## Command line arguments
- `--skipintro`/`-si` automatically skips the game's splash screen.
- `--model`/`-m` overrides the `deviceModel`. Handy for testing for other devices, such as Android or Roku.
- `--deletedata`/`-dd` prompts to delete all save data (settings.lua and highscores.lua).
- `--run`/`+..` runs a line of Lua code. Examples: `--run "releaseBuild = true"` `+"autoScale = 240"`
- `--gamelogic`/`-gl` overrides the path to `scripts/gamelogic.lua`. Handy for testing precompiled Lua support.
- `--datapath`/`-dp` overrides the default path to `data/` and uses a new save data subfolder. Useful for quickly testing different versions of Angry Birds without different folders or symbolic links.

## Acknowledgements
[FiOne](https://github.com/Rerumu/FiOne) is used to run compiled Lua files (with some edits).
The libcrypto library, a part of [OpenSSL](https://github.com/openssl/openssl), is used to decrypt encrypted Lua files.
- libcrypto-3.dll is required to use it: https://slproweb.com/products/Win32OpenSSL.html
[love-webp](https://github.com/ImagicTheCat/love-webp) is used to read WebP images.
[7-Zip](https://www.7-zip.org/) is used to extract Lua files compressed with 7z.
- 7z.exe is required to use it.