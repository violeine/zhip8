const std = @import("std");
const chip8 = @import("chip8.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const pixel = struct { w: c_int = 8, h: c_int = 8 }{};

var quit = false;

fn draw(renderer: *c.SDL_Renderer) void {
    for (0..32) |y| {
        for (0..64) |x| {
            const u = @intCast(c_int, pixel.w * x);
            const v = @intCast(c_int, pixel.h * y);
            if (chip8.frame[y * 64 + x] != 0) {
                _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            } else {
                _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            }
            const p = c.SDL_Rect{ .x = u, .y = v, .w = pixel.w, .h = pixel.h };
            _ = c.SDL_RenderFillRect(renderer, &p);
        }
    }
    _ = c.SDL_RenderPresent(renderer);
}

fn input() void {
    var e: c.SDL_Event = undefined;
    _ = c.SDL_PollEvent(&e);
    switch (e.type) {
        c.SDL_QUIT => quit = true,
        else => {},
    }
}

pub fn main() !void {
    _ = try chip8.load();
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to init SDL: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("zhip8", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 64 * pixel.w, 32 * pixel.h, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Unable to init SDL window: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to init SDL renderer: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_RenderPresent(renderer);

    while (!quit) {
        input();
        chip8.execute(chip8.fetch());
        draw(renderer);
    }
}
