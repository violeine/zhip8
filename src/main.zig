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
}

fn input() void {
    var e: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&e) != 0) {
        switch (e.type) {
            c.SDL_QUIT => quit = true,
            c.SDL_KEYDOWN => {
                switch (e.key.keysym.sym) {
                    c.SDLK_1 => chip8.keys[0x1] = 1,
                    c.SDLK_2 => chip8.keys[0x2] = 1,
                    c.SDLK_3 => chip8.keys[0x3] = 1,
                    c.SDLK_4 => chip8.keys[0xc] = 1,
                    c.SDLK_q => chip8.keys[0x4] = 1,
                    c.SDLK_w => chip8.keys[0x5] = 1,
                    c.SDLK_e => chip8.keys[0x6] = 1,
                    c.SDLK_r => chip8.keys[0xd] = 1,
                    c.SDLK_a => chip8.keys[0x7] = 1,
                    c.SDLK_s => chip8.keys[0x8] = 1,
                    c.SDLK_d => chip8.keys[0x9] = 1,
                    c.SDLK_f => chip8.keys[0xe] = 1,
                    c.SDLK_z => chip8.keys[0xa] = 1,
                    c.SDLK_x => chip8.keys[0x0] = 1,
                    c.SDLK_c => chip8.keys[0xb] = 1,
                    c.SDLK_v => chip8.keys[0xf] = 1,
                    else => {},
                }
            },
            c.SDL_KEYUP => {
                switch (e.key.keysym.sym) {
                    c.SDLK_1 => {
                        chip8.keys[0x1] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x1;
                    },
                    c.SDLK_2 => {
                        chip8.keys[0x2] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x2;
                    },
                    c.SDLK_3 => {
                        chip8.keys[0x3] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x3;
                    },
                    c.SDLK_4 => {
                        chip8.keys[0xc] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xc;
                    },
                    c.SDLK_q => {
                        chip8.keys[0x4] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x4;
                    },
                    c.SDLK_w => {
                        chip8.keys[0x5] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x5;
                    },
                    c.SDLK_e => {
                        chip8.keys[0x6] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x6;
                    },
                    c.SDLK_r => {
                        chip8.keys[0xd] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xd;
                    },
                    c.SDLK_a => {
                        chip8.keys[0x7] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x7;
                    },
                    c.SDLK_s => {
                        chip8.keys[0x8] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x8;
                    },
                    c.SDLK_d => {
                        chip8.keys[0x9] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x9;
                    },
                    c.SDLK_f => {
                        chip8.keys[0xe] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xe;
                    },
                    c.SDLK_z => {
                        chip8.keys[0xa] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xa;
                    },
                    c.SDLK_x => {
                        chip8.keys[0x0] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0x0;
                    },
                    c.SDLK_c => {
                        chip8.keys[0xb] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xb;
                    },
                    c.SDLK_v => {
                        chip8.keys[0xf] = 0;
                        if (chip8.waitKey) chip8.keypressed = 0xf;
                    },
                    else => {},
                }
                chip8.waitKey = false;
            },
            else => {},
        }
    }
}

pub fn main() !void {
    _ = try chip8.load();
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to init SDL: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("zhip8", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 64 * pixel.w, 32 * pixel.h, c.SDL_WINDOW_METAL) orelse {
        c.SDL_Log("Unable to init SDL window: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    };
    defer c.SDL_DestroyWindow(screen);
    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_VSYNC, "0");
    _ = c.SDL_GL_SetSwapInterval(0);
    const renderer = c.SDL_CreateRenderer(screen, 0, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to init SDL renderer: %s", c.SDL_GetError());
        return error.SDLInitFailed;
    };
    _ = c.SDL_RenderSetVSync(renderer, 0);
    defer c.SDL_DestroyRenderer(renderer);
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_RenderPresent(renderer);
    while (!quit) {
        const start: f64 = @intToFloat(f64, c.SDL_GetPerformanceCounter());
        input();
        if (chip8.DT > 0) chip8.DT -= 1;
        if (chip8.ST > 0) chip8.ST -= 1;
        for (0..9) |_| {
            if (!chip8.waitKey) {
                chip8.execute(chip8.fetch());
            }
        }
        draw(renderer);
        _ = c.SDL_RenderPresent(renderer);
        const end: f64 = @intToFloat(f64, c.SDL_GetPerformanceCounter());
        const elapsed: f64 = (end - start) / @intToFloat(f64, c.SDL_GetPerformanceFrequency());
        std.debug.print("current FPS: {d}\n", .{1.0 / elapsed});
    }
}
