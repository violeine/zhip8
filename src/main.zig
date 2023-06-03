const std = @import("std");
const chip8 = @import("chip8.zig");

pub fn main() !void {
    _ = try chip8.load();
    try chip8.debug();
    while (true) {
        chip8.execute(chip8.fetch());
    }
}
