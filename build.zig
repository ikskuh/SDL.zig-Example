const std = @import("std");

/// this namespace contains all packages we use in our program.
/// this is just a convention i follow, it's not required, but very convenient and
/// allows cross-references between packages
const pkgs = struct {
    const sdl = std.build.Pkg{
        .name = "sdl",
        .path = "./deps/sdl/src/lib.zig",
    };
};

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("sdl-demo", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addPackage(pkgs.sdl);

    exe.linkLibC();

    if (target.isWindows()) {
        // linking on windows is sadly not as trivial as on linux:
        // we have to respect 4 different configurations {x86,x64}*{msvc,mingw}
        const sdk_path = b.option([]const u8, "sdl-sdk", "The path to the SDL2 sdk") orelse @panic("sdl-sdk must be given for windows builds!");
        const sdk_image_path = b.option([]const u8, "sdl-image-sdk", "The path to the SDL2_image sdk") orelse @panic("sdl-image-sdk must be given for windows builds!");
        const sdl_static = if (target.getAbi() == .msvc)
            false
        else
            b.option(bool, "sdl-static", "Choses whether to link SDL statically or dynamically. Default is dynamic") orelse false;

        // compute and add the include paths for both SDL2 and SDL_image
        const include_path = if (target.getAbi() == .msvc)
            "include/SDL2"
        else if (target.getCpuArch() == .x86_64)
            "x86_64-w64-mingw32/include/SDL2"
        else
            "i686-w64-mingw32/include/SDL2";

        exe.addIncludeDir(try std.fs.path.join(b.allocator, &[_][]const u8{
            sdk_path,
            include_path,
        }));
        exe.addIncludeDir(try std.fs.path.join(b.allocator, &[_][]const u8{
            sdk_image_path,
            include_path,
        }));

        // link the right libraries

        if (target.getAbi() == .msvc) {
            // MSVC uses lib/$ARCH as paths:
            const library_path = if (target.getCpuArch() == .x86_64)
                "lib/x64/"
            else
                "lib/x86/";

            // and links those as normal libraries
            exe.addLibPath(try std.fs.path.join(b.allocator, &[_][]const u8{
                sdk_path,
                library_path,
            }));
            exe.addLibPath(try std.fs.path.join(b.allocator, &[_][]const u8{
                sdk_image_path,
                library_path,
            }));

            exe.linkSystemLibrary("SDL2");
            exe.linkSystemLibrary("SDL2_image");
        } else {
            // mingw uses either static or dynamically built object files
            const library_path = if (target.getCpuArch() == .x86_64)
                "x86_64-w64-mingw32/lib"
            else
                "i686-w64-mingw32/lib";

            exe.addObjectFile(try std.fs.path.join(b.allocator, &[_][]const u8{
                sdk_path,
                library_path,
                if (sdl_static)
                    "libSDL2.a"
                else
                    "libSDL2.dll.a",
            }));
            exe.addObjectFile(try std.fs.path.join(b.allocator, &[_][]const u8{
                sdk_image_path,
                library_path,
                if (sdl_static)
                    "libSDL2_image.a"
                else
                    "libSDL2_image.dll.a",
            }));

            if (sdl_static) {
                // link all system libraries for SDL2
                const static_libs = [_][]const u8{
                    "setupapi",
                    "user32",
                    "gdi32",
                    "winmm",
                    "imm32",
                    "ole32",
                    "oleaut32",
                    "shell32",
                    "version",
                    "uuid",
                };
                for (static_libs) |lib|
                    exe.linkSystemLibrary(lib);
            }
        }

        // copy the right files into the output directory:

        const binary_path = if (target.getAbi() == .msvc)
            if (target.getCpuArch() == .x86_64)
                "lib/x64"
            else
                "lib/x86"
        else if (target.getCpuArch() == .x86_64)
            "x86_64-w64-mingw32/bin"
        else
            "i686-w64-mingw32/bin";

        if (!sdl_static) {
            b.installBinFile(
                try std.fs.path.join(b.allocator, &[_][]const u8{
                    sdk_path,
                    binary_path,
                    "SDL2.dll",
                }),
                "SDL2.dll",
            );
            b.installBinFile(
                try std.fs.path.join(b.allocator, &[_][]const u8{
                    sdk_image_path,
                    binary_path,
                    "SDL2_image.dll",
                }),
                "SDL2_image.dll",
            );
        }

        // required DLLs for sdl_image
        const image_dlls = [_][]const u8{
            "libjpeg-9.dll",
            "libpng16-16.dll",
            "libtiff-5.dll",
            "libwebp-7.dll",
            "zlib1.dll",
        };

        for (image_dlls) |dll| {
            b.installBinFile(
                try std.fs.path.join(b.allocator, &[_][]const u8{
                    sdk_image_path,
                    binary_path,
                    dll,
                }),
                std.fs.path.basename(dll),
            );
        }
    } else if (target.isLinux()) {
        // on linux, we should rely on the system libraries to "just work"
        exe.linkSystemLibrary("sdl2");
        exe.linkSystemLibrary("SDL2_image");
    } else {
        @panic("Chosen OS is not supported yet!");
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
