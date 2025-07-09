const Self = @This();

base: *CanvasLayer,
coins_label: *Label = undefined,
player: *Node3D = undefined,

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    // onready
    self.coins_label = Label.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Coins"))).?,
    ).?;

    // TODO: exported property
    self.player = Node3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("../Player"))).?,
    ).?;

    // TODO: connect to player coin_collected signal
}

pub fn _onCoinCollected(self: *Self, coins: u32) void {
    const coins_text = String.fromUtf8(std.fmt.allocPrint(
        godot.heap.general_allocator,
        "{d}",
        .{coins},
    ) catch unreachable);
    defer coins_text.deinit();

    self.coins_label.setText(coins_text);
}

const Engine = godot.class.Engine;
const String = godot.builtin.String;
const Label = godot.class.Label;
const CanvasLayer = godot.class.CanvasLayer;
const Node3D = godot.class.Node3D;

const std = @import("std");
const godot = @import("gdzig");
