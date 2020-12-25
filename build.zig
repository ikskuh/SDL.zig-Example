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

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("sdl-demo", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addPackage(pkgs.sdl);

    exe.linkLibC();

    if (target.isWindows()) {
        // link windows
    } else if (target.isLinux()) {
        // on linux, we should rely on the system libraries
        exe.linkSystemLibrary("sdl2");
        exe.linkSystemLibrary("SDL2_image");
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
