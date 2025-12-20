# Angry Birds on LÖVE

To download, head to https://github.com/romoney5/angry-birds-love2d/releases/latest , and download `angrybirds_love2d.love`.

Make sure you have [LÖVE](https://love2d.org/) installed. After that, you can simply double-click the .love file to play.

You can also test from the source code without a .love file. Download and unzip the zip file from the Code dropdown. For Windows, go to C:\Program Files\LOVE\ and copy lovec.exe (or love.exe) to the unzipped folder. Finally drag main.lua to lovec.exe.

If you are on Linux, you should be able to download a LÖVE Flatpak, then go into the project folder, open a terminal, and run `love .`

## Command line arguments
- `--skipintro`/`-si` skips the splashscreen of the game.
- `--model`/`-m` overrides the `deviceModel`. Handy for testing for other devices, such as Android or Roku.
- `--deletedata`/`-dd` prompts to delete all save data (settings.lua and highscores.lua).