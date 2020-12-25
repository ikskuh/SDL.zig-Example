const std = @import("std");
const sdl = @import("sdl");

pub fn main() !void {
    try sdl.init(.{
        .video = true,
        .events = true,
    });
    defer sdl.quit();

    try sdl.image.init(.{
        .png = true,
    });
    defer sdl.image.quit();

    // Create a new window with "DVD Demo" as name.
    var window = try sdl.createWindow(
        "DVD Demo",
        .centered,
        .centered,
        1280,
        720,
        .{},
    );
    defer window.destroy();

    // Create a accelerated renderer for the window,
    // but don't care which tech is actually used.
    var renderer = try sdl.createRenderer(
        window,
        null,
        .{
            .accelerated = true,
            .present_vsync = true,
        },
    );
    defer renderer.destroy();

    var logo = try sdl.image.loadTexture(
        renderer,
        "./img/dvd.png",
    );
    defer logo.destroy();

    var logo_info = try logo.query();

    var x: c_int = 0;
    var y: c_int = 0;

    // will be flipped in the first round
    var dx: c_int = 1;
    var dy: c_int = 1;

    main_loop: while (true) {
        // Main event loop, poll events from SDL
        // and dispatch them
        while (sdl.pollEvent()) |event| {
            switch (event) {
                // Someone has clicked the [X] button (or closed the window otherwise)
                .quit => break :main_loop,

                // A key was pressed
                .key_down => |kev| {
                    switch (kev.keysym.sym) {
                        sdl.c.SDLK_ESCAPE => break :main_loop,
                        else => {},
                    }
                },

                else => {},
            }
        }

        var window_size = window.getSize();

        // Implement bouncing
        if (x <= 0)
            dx = 1;
        if (x >= @intCast(usize, window_size.width) - logo_info.width)
            dx = -1;

        if (y <= 0)
            dy = 1;
        if (y >= @intCast(usize, window_size.height) - logo_info.height)
            dy = -1;

        x += dx;
        y += dy;

        // Clear the screen to a very dark gray
        try renderer.setColor(sdl.Color.rgb(0x10, 0x10, 0x10));
        try renderer.clear();

        try renderer.copy(
            logo,
            sdl.Rectangle{
                .x = x,
                .y = y,
                .width = @intCast(c_int, logo_info.width),
                .height = @intCast(c_int, logo_info.height),
            },
            null,
        );

        // Present the screen contents
        renderer.present();
    }
}
