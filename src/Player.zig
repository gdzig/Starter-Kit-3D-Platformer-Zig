const Self = @This();

coin_collected: Signal,

base: *CharacterBody3D,
movement_speed: f64 = 250.0,
jump_strength: f64 = 7.0,
movement_velocity: Vector3 = .zero,
rotation_direction: f64 = 0,
gravity: f64 = 0,
previously_floored: bool = false,
jump_single: bool = true,
jump_double: bool = true,
coins: u32 = 0,

view: *Node3D = undefined,
particles_trail: *CPUParticles3D = undefined,
sound_footsteps: *AudioStreamPlayer = undefined,
model: *Node3D = undefined,
animation: *AnimationPlayer = undefined,
audio: *Audio = undefined,

pub fn init(base: *CharacterBody3D) Self {
    return .{
        .base = base,
        .coin_collected = .init(),
    };
}

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    // onready
    self.particles_trail = CPUParticles3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("./ParticlesTrail"))).?,
    ).?;

    self.sound_footsteps = AudioStreamPlayer.downcast(
        self.base.getNode(.fromString(.fromLatin1("./SoundFootsteps"))).?,
    ).?;

    self.model = Node3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Character"))).?,
    ).?;

    self.animation = AnimationPlayer.downcast(
        self.base.getNode(.fromString(.fromLatin1("./Character/AnimationPlayer"))).?,
    ).?;

    self.view = Node3D.downcast(
        self.base.getNode(.fromString(.fromLatin1("../View"))).?,
    ).?;

    self.audio = godot.meta.downcast(
        *Audio,
        self.base.getNode(.fromString(.fromLatin1("/root/Audio"))).?,
    ).?;
}

pub fn _physicsProcess(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    // handle functions
    self.handleControls(delta);
    self.handleGravity(delta);
    self.handleEffects(delta);

    // movement
    var applied_velocity: Vector3 = self.base.getVelocity()
        .lerp(self.movement_velocity, @floatCast(delta * 10));
    applied_velocity.y = @floatCast(-self.gravity);
    self.base.setVelocity(applied_velocity);

    _ = self.base.moveAndSlide();

    // rotation
    const velocity = self.base.getVelocity();
    const direction: Vector2 = .initXY(velocity.z, velocity.x);
    if (direction.length() > 0) {
        self.rotation_direction = direction.angle();
    }

    var rotation = self.base.getRotation();
    rotation.y = @floatCast(math.lerpAngle(@floatCast(rotation.y), @floatCast(self.rotation_direction), @floatCast(delta * 10)));
    self.base.setRotation(rotation);

    // falling/respawning
    if (self.base.getPosition().y < -10) {
        _ = self.base.getTree().?.reloadCurrentScene();
    }

    // animation for scale (jumping and landing)
    var model_scale = self.model.getScale();
    model_scale = model_scale.lerp(.one, @floatCast(delta * 10));

    self.model.setScale(model_scale);

    // animation when landing
    if (self.base.isOnFloor() and self.gravity > 2 and !self.previously_floored) {
        self.model.setScale(.initXYZ(1.25, 0.75, 1.25));
        // Audio.play("res://sounds/land.ogg")
    }

    self.previously_floored = self.base.isOnFloor();
}

fn handleControls(self: *Self, delta: f64) void {
    var input: Vector3 = .zero;
    input.x = @floatCast(Input.getAxis(.fromLatin1("move_left"), .fromLatin1("move_right")));
    input.z = @floatCast(Input.getAxis(.fromLatin1("move_forward"), .fromLatin1("move_back")));

    const rotation = self.view.getRotation();
    input = input.rotated(.up, rotation.y);

    if (input.length() > 1) {
        input = input.normalized();
    }

    self.movement_velocity = input.mulFloat(@floatCast(self.movement_speed * delta));

    // jumping
    if (Input.isActionJustPressed(.fromLatin1("jump"), .{})) {
        if (self.jump_single or self.jump_double) {
            self.jump();
        }
    }
}

fn jump(self: *Self) void {
    // Audio.play("res://sounds/jump.ogg")
    // TODO: this doesn't work
    self.audio.play(.fromLatin1("res://sounds/jump.ogg"));

    self.gravity = -self.jump_strength;
    self.model.setScale(.initXYZ(0.5, 1.5, 0.5));

    if (self.jump_single) {
        self.jump_single = false;
        self.jump_double = true;
    } else {
        self.jump_double = false;
    }
}

fn handleGravity(self: *Self, delta: f64) void {
    self.gravity += (25 * @as(f64, @floatCast(delta)));

    if (self.gravity > 0 and self.base.isOnFloor()) {
        self.jump_single = true;
        self.gravity = 0;
    }
}

fn handleEffects(self: *Self, delta: f64) void {
    self.particles_trail.setEmitting(false);
    self.sound_footsteps.setStreamPaused(true);

    const current_animation = self.animation.getCurrentAnimation();

    if (self.base.isOnFloor()) {
        const velocity = self.base.getVelocity();
        var horizontal_velocity: Vector2 = .initXY(velocity.x, velocity.z);

        const speed_factor = horizontal_velocity.length() / self.movement_speed / delta;

        if (speed_factor > 0.05) {
            if (!current_animation.eql(.fromLatin1("walk"))) {
                self.animation.play(.{
                    .name = .fromLatin1("walk"),
                    .custom_speed = 0.1,
                });
            }

            if (speed_factor > 0.3) {
                self.sound_footsteps.setStreamPaused(false);
                self.sound_footsteps.setPitchScale(@floatCast(speed_factor));
            }

            if (speed_factor > 0.75) {
                self.particles_trail.setEmitting(true);
            }
        } else if (!current_animation.eql(.fromLatin1("idle"))) {
            self.animation.play(.{
                .name = .fromLatin1("idle"),
                .custom_speed = 0.1,
            });
        }
    } else if (!current_animation.eql(.fromLatin1("jump"))) {
        self.animation.play(.{
            .name = .fromLatin1("jump"),
            .custom_speed = 0.1,
        });
    }
}

pub fn collectCoin(self: *Self) void {
    self.coins += 1;
    self.coin_collected.emit(self.coins);
}

const std = @import("std");

const godot = @import("gdzig");
const math = godot.math;
const Input = godot.class.Input;
const Engine = godot.class.Engine;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const Vector2 = godot.builtin.Vector2;
const Vector3 = godot.builtin.Vector3;
const Signal = godot.builtin.Signal;
const Node3D = godot.class.Node3D;
const Node = godot.class.Node;
const NodePath = godot.builtin.NodePath;
const CPUParticles3D = godot.class.CPUParticles3D;
const CharacterBody3D = godot.class.CharacterBody3D;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const AnimationPlayer = godot.class.AnimationPlayer;
const Variant = godot.builtin.Variant;

const Audio = @import("autoload/AudioAutoload.zig");
