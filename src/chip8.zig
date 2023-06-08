const std = @import("std");

var memory = [_]u8{0} ** 4096;
var v = [_]u8{0} ** 16;
var I: u16 = 0;
var DT: u8 = 0;
var ST: u8 = 0;
var PC: u16 = 0x200;
var SP: u8 = 0;
var stack = [_]u16{0} ** 16;
pub var frame = [_]u2{0} ** WIDTH ** HEIGHT;
const WIDTH = 64;
const HEIGHT = 32;

pub fn load() !usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    const size = try file.readAll(memory[0x200..]);
    return size;
}

pub fn debug() !void {
    for (0x200..0x300) |value| {
        if (value % 15 == 0) std.debug.print("\n", .{});
    }
}

pub fn fetch() u16 {
    const op: u16 = (@as(u16, memory[PC]) << 8) | memory[PC + 1];
    PC += 2;
    return op;
}
const bitMasks = [_]u8{
    0b10_000_000,
    0b01_000_000,
    0b00_100_000,
    0b00_010_000,
    0b00_001_000,
    0b00_000_100,
    0b00_000_010,
    0b00_000_001,
};

pub fn execute(op: u16) void {
    const x = (op & 0x0f00) >> 8;
    const y = (op & 0x00f0) >> 4;
    const kk = @truncate(u8, op & 0x00ff);
    const nnn = @truncate(u12, op & 0x0fff);
    const n = @truncate(u8, op & 0x000f);
    switch (op) {
        //clear
        0x00e0 => {
            for (0..WIDTH * HEIGHT) |i| {
                frame[i] = 0;
            }
        },
        //return
        0x00ee => {
            SP -= 1;
            PC = stack[SP];
        },
        else => switch ((op & 0xf000) >> 4 * 3) {
            0x1 => PC = nnn, //1nnn
            0x2 => { //2nnn
                stack[SP] = PC;
                SP += 1;
                PC = nnn;
            },
            0x3 => if (v[x] == kk) {
                PC += 2;
            },
            0x4 => if (v[x] != kk) {
                PC += 2;
            },
            0x6 => {
                v[x] = kk;
            },
            0x7 => v[x] +%= kk,
            0xA => I = nnn, //Annn
            0xB => PC = nnn + v[0x0],
            0xC => {},
            0xD => {
                for (0..n) |i| {
                    const d = memory[I + i];
                    for (bitMasks, 0..8) |mask, e| {
                        const r = (v[y] +% i) % 32;
                        const c = (v[x] +% e) % 64;
                        const pos = (WIDTH * r + c) % (WIDTH * HEIGHT);
                        var value: u1 = if ((d & mask) > 0) 1 else 0;
                        const t = frame[pos] ^ value;
                        if (t == 0) v[0xf] = 1 else v[0xf] = 0;
                        frame[pos] = t;
                    }
                }
            },
            else => switch (op & 0xf00f) {
                0x5000 => {
                    if (v[x] == v[y]) {
                        PC += 2;
                    }
                },
                0x8000 => v[x] = v[y],
                0x8001 => v[x] |= v[y],
                0x8002 => v[x] &= v[y],
                0x8003 => v[x] ^= v[y],
                0x8004 => {
                    v[0xf] = if (v[x] +% v[y] > 255) 1 else 0;
                    v[x] +%= v[y];
                },
                0x8005 => {
                    v[0xf] = if (v[x] > v[y]) 1 else 0;
                    v[x] -%= v[y];
                },
                0x8006 => {
                    v[0xf] = v[x] & 0x01;
                    v[x] >>= 1;
                },
                0x8007 => {
                    v[0xf] = if (v[y] > v[x]) 1 else 0;
                    v[x] = v[y] -% v[x];
                },
                0x800e => {
                    v[0xf] = v[x] & 0xa0;
                    v[x] <<= 1;
                },
                0x9000 => {
                    if (v[x] != v[y]) PC += 2;
                },
                else => switch (op & 0xf0ff) {
                    0xe09e => {},
                    0xe0a1 => {},
                    0xf007 => v[x] = DT,
                    0xf00a => {},
                    0xf015 => DT = v[x],
                    0xf018 => ST = v[x],
                    0xf01e => I += v[x],
                    0xf029 => {},
                    0xf033 => {
                        memory[I] = v[x] / 100;
                        var t = v[x] % 100;
                        memory[I + 1] = t / 10;
                        memory[I + 2] = t % 10;
                    },
                    0xf055 => {
                        for (0..(x + 1)) |j| {
                            memory[I + j] = v[j];
                        }
                    },
                    0xf065 => {
                        for (0..(x + 1)) |j| {
                            v[j] = memory[I + j];
                        }
                    },
                    else => {},
                },
            },
        },
    }
}

pub fn draw() void {
    for (0..HEIGHT) |y| {
        for (0..WIDTH) |x| {
            std.debug.print("{s}", .{if (frame[y * WIDTH + x] > 0) "█" else " "});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}
