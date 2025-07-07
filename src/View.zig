const Self = @This();

base: *Node3D,
target: ?*Node3D = null,
zoom_minimum: f64 = 16.0,
zoom_maximum: f64 = 4.0,
zoom_speed: f64 = 10.0,
rotation_speed: f64 = 120.0,

camera_rotation: Vector3 = .zero,
zoom: f64 = 10.0,
camera: *Camera3D = undefined,

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    // onready
    self.camera = Camera3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Camera"))).?,
    ) catch std.debug.panic("Failed to find Camera", .{});

    // TODO: exported variable
    self.target = Node3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("../Player"))).?,
    ) catch std.debug.panic("Failed to find Player", .{});

    // Initial rotation
    self.camera_rotation = self.base.getRotationDegrees();
}

pub fn _physicsProcess(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    // Set position and rotation to targets
    if (self.target) |target| {
        const target_pos = target.getPosition();
        const current_pos = self.base.getPosition();
        self.base.setPosition(current_pos.lerp(target_pos, @floatCast(delta * 4)));
    }

    const current_rotation = self.base.getRotationDegrees();
    self.base.setRotationDegrees(current_rotation.lerp(self.camera_rotation, @floatCast(delta * 6)));

    const camera_pos = self.camera.getPosition();
    const target_camera_pos = Vector3.initXYZ(0, 0, @floatCast(self.zoom));
    self.camera.setPosition(camera_pos.lerp(target_camera_pos, @floatCast(8 * delta)));

    self.handleInput(delta);
}

fn handleInput(self: *Self, delta: f64) void {
    // Rotation
    var input: Vector3 = .zero;

    input.y = @floatCast(Input.getAxis(.fromLatin1("camera_left"), .fromLatin1("camera_right")));
    input.x = @floatCast(Input.getAxis(.fromLatin1("camera_up"), .fromLatin1("camera_down")));

    const limited_input = if (input.length() > 1.0) input.normalized() else input;
    self.camera_rotation = self.camera_rotation.add(limited_input.mulFloat(@floatCast(self.rotation_speed * delta)));
    self.camera_rotation.x = std.math.clamp(self.camera_rotation.x, -80, -10);

    // Zooming
    self.zoom += @as(f64, @floatCast(Input.getAxis(.fromLatin1("zoom_in"), .fromLatin1("zoom_out")))) * self.zoom_speed * delta;
    self.zoom = std.math.clamp(self.zoom, self.zoom_maximum, self.zoom_minimum);
}

const Input = godot.class.Input;
const Engine = godot.class.Engine;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const Vector3 = godot.builtin.Vector3;

const Node3D = godot.class.Node3D;
const Camera3D = godot.class.Camera3D;
const NodePath = godot.builtin.NodePath;

const std = @import("std");
const godot = @import("gdzig");
const math = godot.math;
