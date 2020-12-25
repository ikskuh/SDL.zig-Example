# SDL2 with Zig

This is a simple example project that renders the classic *bouncing DVD logo* with SDL2. This example is a minimal example on how to set up a fully deployable project with Zig.

![Screenshot](https://mq32.de/public/9223d8240a1d75cf9387243a0696efd882aab3b0.png)

## Building

This example requires **Zig 0.7.1**, you can obtain a copy for your system [here](https://ziglang.org/download/).

**Do not download a `master` build! There is currently something broken in `translate-c` that makes it impossible to import SDL2 headers!**

### Prerequisites
Clone this repository with `git` recursively and change into the cloned working directory:
```
git clone https://github.com/MasterQ32/SDL.zig-Example sdl-example --recursive
cd sdl-example
```

If you don't want to use submodules, obtain a copy of [SDL.zig](https://github.com/MasterQ32/SDL.zig) and copy it into `deps/sdl`.

### Linux
Install the development packages listed below and invoke `zig build`.

#### Packages (Debian, Ubuntu)
- `libsdl2-dev`
- `libsdl2-image-dev`

#### Packages (Arch Linux, Manjaro)
- `sdl2`
- `sdl2_image`

### Windows
Windows has no pre-built SDL2 neither a package manager. This means you have to download the development libraries from [libsdl.org](https://www.libsdl.org/download-2.0.php) for either *Visual C++ 32/64-bit* or *MinGW 32/64-bit* and extract it into a folder.

The same must be done for the [`SDL_image` development libraries](https://www.libsdl.org/projects/SDL_image/). Chose the same abi/compiler as your SDL2 download above.

Then, use
```
zig build -Dsdl-sdk=C:\Users\MYUSERNAME\...\SDL2-2.X.Y -Dsdl-image-sdk=C:\Users\MYUSERNAME\...\SDL2_image-2.Z.W
```
to build your project. The build script will auto-detect depending on your target if the *Visual C++ 32/64-bit* or *MinGW 32/64-bit* folder layout should be used.

### Cross-Build (Host: Linux, Target: Windows)
Just follow the instructions for building for *Windows*, but use *MinGW 32/64-bit*. Using *Visual C++ 32/64-bit* will **not** work!

### Cross-Build (Host: Windows, Target: Linux)
Not supported atm. Use WSL for this.

## Known Problems

### `lld-link: error: undefined symbol: ___chkstk_ms`
For the target `target=i386-windows-gnu` this error is emitted. This is probably missing in `compiler_rt`

### `***-windows-msvc`
This target is not tested yet