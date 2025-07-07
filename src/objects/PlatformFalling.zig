const Self = @This();

base: *Node3D,
falling: bool = false,
gravity: f64 = 0.0,

pub fn _process(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    // Animate scale
    const current_scale = self.base.getScale();
    const target_scale = Vector3.one;
    self.base.setScale(current_scale.lerp(target_scale, @floatCast(delta * 10)));

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
    if (!self.falling) {
        // Audio.play("res://sounds/fall.ogg") - TODO: implement audio

        // Animate scale
        self.base.setScale(Vector3.initXYZ(1.25, 1, 1.25));
    }

    self.falling = true;
}

const Engine = godot.class.Engine;
const Node3D = godot.class.Node3D;
const Vector3 = godot.builtin.Vector3;

const std = @import("std");
const godot = @import("gdzig");
