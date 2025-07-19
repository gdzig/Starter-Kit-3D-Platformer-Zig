const Self = @This();

base: *Node3D,
falling: bool = false,
gravity: f64 = 0.0,

area_3d: ?*Area3D = null,
audio: *Audio = undefined,

pub fn _bindMethods() void {
    godot.registerMethod(Self, "_onBodyEntered");
}

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    self.area_3d = Area3D.downcast(self.base.getNodeOrNull(.fromString(.fromLatin1("./Area3D"))));
    self.audio = Audio.getAutoload(self.base.getTree());

    if (self.area_3d) |area| {
        godot.connect(area, Area3D.BodyEnteredSignal, .fromClosure(self, &_onBodyEntered));
    }
}

pub fn _process(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    // Animate scale
    const current_scale = self.base.getScale();
    const target_scale = Vector3.one;
    self.base.setScale(current_scale.lerp(target_scale, delta * 10));

    // Apply gravity
    var position = self.base.getPosition();
    position.y -= @floatCast(self.gravity * delta);
    self.base.setPosition(position);

    // Remove platform if below threshold
    if (position.y < -10) {
        self.base.queueFree();
    }

    // Increase gravity if falling
    if (self.falling) {
        self.gravity += 0.25;
    }
}

pub fn _onBodyEntered(self: *Self, _body: *Node3D) void {
    _ = _body;
    std.debug.print("Body entered platform\n", .{});

    if (!self.falling) {
        self.audio.play(.fromLatin1("res://sounds/fall.ogg"));

        // Animate scale
        self.base.setScale(Vector3.initXYZ(1.25, 1, 1.25));
    }

    self.falling = true;
}

const std = @import("std");

const godot = @import("gdzig");
const Area3D = godot.class.Area3D;
const Engine = godot.class.Engine;
const Node3D = godot.class.Node3D;
const Vector3 = godot.builtin.Vector3;

const Audio = @import("../autoload/AudioAutoload.zig");
