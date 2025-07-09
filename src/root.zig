var gpa: std.heap.DebugAllocator(.{}) = .init;

comptime {
    godot.entrypoint("my_extension_init", .{
        .init = &init,
        .deinit = &deinit,
    });
}

fn init(level: godot.InitializationLevel) void {
    if (level != .scene) {
        return;
    }

    godot.registerClass(AudioAutoload);
    godot.registerClass(Player);
    godot.registerClass(View);
    godot.registerClass(HUD);
    godot.registerClass(Cloud);
    godot.registerClass(Coin);
    godot.registerClass(PlatformFalling);
}

fn deinit(level: godot.InitializationLevel) void {
    if (level == .core) {
        _ = gpa.deinit();
    }
}

const AudioAutoload = @import("autoload/AudioAutoload.zig");
const Player = @import("Player.zig");
const View = @import("View.zig");
const HUD = @import("HUD.zig");
const Cloud = @import("objects/Cloud.zig");
const Coin = @import("objects/Coin.zig");
const PlatformFalling = @import("objects/PlatformFalling.zig");

const std = @import("std");
const godot = @import("gdzig");
