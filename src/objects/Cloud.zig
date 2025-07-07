const Self = @This();

var rng: ?std.Random = null;

base: *Node,
target: *Node3D = undefined,
time: f64 = 0.0,
random_velocity: f64 = 0.0,
random_time: f64 = 0.0,

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    if (rng == null) {
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
        rng = prng.random();
    }

    self.random_velocity = rng.?.float(f64) * 1.9 + 0.1; // range 0.1 to 2.0
    self.random_time = rng.?.float(f64) * 1.9 + 0.1; // range 0.1 to 2.0

    self.target = Node3D.downcast(self.base.getParent().?) catch @panic("Failed to downcast parent to Node3D");
}

pub fn _process(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    var position = self.target.getPosition();
    position.y += @floatCast((@cos(self.time * self.random_time) * self.random_velocity) * delta);
    self.target.setPosition(position);

    self.time += delta;
}

const Node = godot.class.Node;
const Node3D = godot.class.Node3D;
const Engine = godot.class.Engine;
const Vector3 = godot.builtin.Vector3;

const std = @import("std");
const godot = @import("gdzig");
