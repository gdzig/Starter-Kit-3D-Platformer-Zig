const Self = @This();

const default_movement_speed: f32 = 250.0;
const default_jump_strength: f32 = 7.0;
const default_gravity: f32 = 0;

base: CharacterBody3D,
view: Node3D,
movement_speed: f32,
jump_strength: f32,
movement_velocity: Vector3,
rotation_direction: f64,
gravity: f32,
previously_floored: bool,
jump_single: bool,
jump_double: bool,
coins: u32,

particles_trail: CPUParticles3D,
sound_footsteps: AudioStreamPlayer,
model: Node3D,
animation: AnimationPlayer,

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    // init variables
    self.movement_speed = default_movement_speed;
    self.jump_strength = default_jump_strength;
    self.gravity = default_gravity;
    self.previously_floored = false;
    self.jump_single = true;
    self.jump_double = true;
    self.coins = 0;

    // onready
    self.particles_trail = CPUParticles3D.downcast(
        self.base.getNode(.fromString(String.fromLatin1("./ParticlesTrail"))).?,
    ) catch std.debug.panic("Failed to find ParticlesTrail", .{});

    self.sound_footsteps = AudioStreamPlayer.downcast(
        self.base.getNode(.fromString(String.fromLatin1("./SoundFootsteps"))).?,
    ) catch std.debug.panic("Failed to find SoundFootsteps", .{});

    self.model = Node3D.downcast(
        self.base.getNode(.fromString(String.fromLatin1("./Character"))).?,
    ) catch std.debug.panic("Failed to find Character", .{});

    self.animation = AnimationPlayer.downcast(
        self.base.getNode(.fromString(String.fromLatin1("./Character/AnimationPlayer"))).?,
    ) catch std.debug.panic("Failed to find AnimationPlayer", .{});
}

pub fn _physicsProcess(self: *Self, delta: f32) void {
    if (Engine.isEditorHint()) return;

    // handle functions
    self.handleControls(delta);
    self.handleGravity(delta);
    self.handleEffects(delta);

    // movement
    var applied_velocity: Vector3 = self.base.getVelocity()
        .lerp(self.movement_velocity, delta * 10);
    applied_velocity.y -= self.gravity;

    self.base.setVelocity(applied_velocity);
    _ = self.base.moveAndSlide();

    // rotation
    const velocity = self.base.getVelocity();
    const direction: Vector2 = .initXY(velocity.z, velocity.x);
    if (direction.length() > 0) {
        self.rotation_direction = direction.angle();
    }

    var rotation = self.base.getRotation();
    rotation.y = @floatCast(math.lerpAngle(@floatCast(rotation.y), self.rotation_direction, delta * 10));

    // falling/respawning
    if (self.base.getPosition().y < -10) {
        _ = self.base.getTree().?.reloadCurrentScene();
    }

    // animation for scale (jumping and landing)
    var model_scale = self.model.getScale();
    model_scale = model_scale.lerp(.one, delta * 10);

    self.model.setScale(model_scale);

    // animation when landing
    if (self.base.isOnFloor() and self.gravity > 2 and !self.previously_floored) {
        self.model.setScale(.initXYZ(1.25, 0.75, 1.25));
        // Audio.play("res://sounds/land.ogg")
    }

    self.previously_floored = self.base.isOnFloor();
}

fn handleControls(self: *Self, delta: f32) void {
    var input: Vector3 = .init();
    input.x = Input.getAxis(.fromLatin1("move_left"), .fromLatin1("move_right"));
    input.z = Input.getAxis(.fromLatin1("move_forward"), .fromLatin1("move_back"));

    const rotation = self.view.getRotation();
    input = input.rotated(Vector3.initXYZ(0, 1, 0), rotation.y);

    if (input.length() > 1) {
        input = input.normalized();
    }

    self.movement_velocity = input.mulFloat(self.movement_speed).mulFloat(delta);

    // jumping
    if (Input.isActionJustPressed(.fromLatin1("jump"), .{})) {
        if (self.jump_single or self.jump_double) {
            self.jump();
        }
    }
}

fn jump(self: *Self) void {
    _ = self; // autofix
    // TODO
}

fn handleGravity(self: *Self, delta: f32) void {
    _ = self; // autofix
    _ = delta; // autofix
}

fn handleEffects(self: *Self, delta: f32) void {
    _ = self; // autofix
    _ = delta; // autofix
}

const Input = godot.class.Input;
const Engine = godot.class.Engine;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const Vector2 = godot.builtin.Vector2;
const Vector3 = godot.builtin.Vector3;
const Node3D = godot.class.Node3D;
const NodePath = godot.builtin.NodePath;
const CPUParticles3D = godot.class.CPUParticles3D;
const CharacterBody3D = godot.class.CharacterBody3D;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const AnimationPlayer = godot.class.AnimationPlayer;

const std = @import("std");
const godot = @import("gdzig");
const math = godot.math;
