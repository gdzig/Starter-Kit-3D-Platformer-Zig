const Self = @This();

base: *Area3D,
time: f64 = 0.0,
grabbed: bool = false,

mesh: *Node3D = undefined,
particles: *CPUParticles3D = undefined,

audio: *Audio = undefined,

pub fn _bindMethods() void {
    godot.registerMethod(Self, "_onBodyEntered");
}

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    // onready
    self.mesh = Node3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Mesh"))).?,
    ).?;

    self.particles = CPUParticles3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Particles"))).?,
    ).?;

    self.audio = Audio.getAutoload(self.base.getTree());

    godot.connect(self.base, Area3D.BodyEnteredSignal, .fromClosure(self, &_onBodyEntered));
}

pub fn _process(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    // Rotation
    self.base.rotateY(2 * delta);

    // Sine movement
    var position = self.base.getPosition();
    position.y += @floatCast((@cos(self.time * 5) * 1) * delta);
    self.base.setPosition(position);

    self.time += delta;
}

pub fn _onBodyEntered(self: *Self, body: *Node3D) void {
    if (self.grabbed) return;

    // Check if body has collect_coin method (assume it's a Player)
    if (body.hasMethod(.fromComptimeLatin1("collectCoin"))) {
        _ = body.call(.fromComptimeLatin1("collectCoin"), &.{});

        self.audio.play(.fromLatin1("res://sounds/coin.ogg"));

        // Make invisible
        self.mesh.queueFree();

        // Stop emitting stars
        self.particles.setEmitting(false);

        self.grabbed = true;
    }
}

const std = @import("std");

const godot = @import("gdzig");
const Engine = godot.class.Engine;
const Node3D = godot.class.Node3D;
const Area3D = godot.class.Area3D;
const CPUParticles3D = godot.class.CPUParticles3D;
const Vector3 = godot.builtin.Vector3;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;

const Audio = @import("../autoload/AudioAutoload.zig");
