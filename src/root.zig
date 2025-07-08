var gpa = GPA.init;

pub export fn my_extension_init(p_get_proc_address: godot.c.GDExtensionInterfaceGetProcAddress, p_library: godot.c.GDExtensionClassLibraryPtr, r_initialization: [*c]godot.c.GDExtensionInitialization) godot.c.GDExtensionBool {
    const allocator = gpa.allocator();
    const plugin = godot.registerPlugin(p_get_proc_address, p_library, r_initialization, allocator, &init, &deinit);

    return plugin;
}

fn init(_: ?*anyopaque, p_level: godot.c.GDExtensionInitializationLevel) void {
    if (p_level != godot.c.GDEXTENSION_INITIALIZATION_SCENE) {
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

fn deinit(_: ?*anyopaque, p_level: godot.c.GDExtensionInitializationLevel) void {
    if (p_level == godot.c.GDEXTENSION_INITIALIZATION_CORE) {
        _ = gpa.deinit();
    }
}

const GPA = std.heap.GeneralPurposeAllocator(.{});

const AudioAutoload = @import("autoload/AudioAutoload.zig");
const Player = @import("Player.zig");
const View = @import("View.zig");
const HUD = @import("HUD.zig");
const Cloud = @import("objects/Cloud.zig");
const Coin = @import("objects/Coin.zig");
const PlatformFalling = @import("objects/PlatformFalling.zig");

const std = @import("std");
const godot = @import("gdzig");
