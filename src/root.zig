var gpa = GPA.init;

pub export fn my_extension_init(p_get_proc_address: godot.c.GDExtensionInterfaceGetProcAddress, p_library: godot.c.GDExtensionClassLibraryPtr, r_initialization: [*c]godot.c.GDExtensionInitialization) godot.c.GDExtensionBool {
    const allocator = gpa.allocator();
    return godot.registerPlugin(p_get_proc_address, p_library, r_initialization, allocator, &init, &deinit);
}

fn init(_: ?*anyopaque, p_level: godot.c.GDExtensionInitializationLevel) void {
    if (p_level != godot.c.GDEXTENSION_INITIALIZATION_SCENE) {
        return;
    }

    godot.registerClass(Audio);
}

fn deinit(_: ?*anyopaque, p_level: godot.c.GDExtensionInitializationLevel) void {
    if (p_level == godot.c.GDEXTENSION_INITIALIZATION_CORE) {
        _ = gpa.deinit();
    }
}

const GPA = std.heap.GeneralPurposeAllocator(.{});
const Audio = @import("Audio.zig");

const std = @import("std");
const godot = @import("gdzig");
