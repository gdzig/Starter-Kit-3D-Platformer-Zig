const Self = @This();

base: Node,
num_players: u32 = 12,
bus: StringName = undefined,
available: ArrayList(AudioStreamPlayer) = undefined,
queue: ArrayList(String) = undefined,

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    self.bus = .fromComptimeLatin1("master");
    self.available = .init(godot.heap.general_allocator);
    self.queue = .init(godot.heap.general_allocator);

    for (0..self.num_players) |_| {
        var player: AudioStreamPlayer = .init();
        player.setVolumeDb(-10);
        player.setBus(self.bus);

        godot.connect(player, "finished", self, "onStreamFinished");
        self.base.addChild(Node.upcast(player), .{});
        self.available.append(player) catch @panic("Failed to append AudioStreamPlayer to list");
    }
}

pub fn _process(self: *Self, delta: f32) void {
    if (Engine.isEditorHint()) return;

    _ = delta; // autofix
    if (self.queue.items.len > 0 and self.available.items.len > 0) {
        var player = self.available.swapRemove(0);
        const stream = AudioStream.downcast(ResourceLoader.load(self.queue.swapRemove(0), .{}).?) catch @panic("Failed to load AudioStream");
        player.setStream(stream);
        player.setPitchScale(@floatCast(godot.random.randfRange(0.9, 1.1)));
        player.play(.{});
    }
}

pub fn onStreamFinished(self: *Self, stream: *godot.class.Object) void {
    const player = AudioStreamPlayer.downcast(stream.*) catch @panic("Failed to downcast AudioStreamPlayer");
    self.available.append(player) catch @panic("Failed to append AudioStreamPlayer to available list");
}

pub fn play(self: *Self, sound_path: String) void {
    self.queue.append(sound_path) catch unreachable;
}

pub fn _exitTree(self: *Self) void {
    if (Engine.isEditorHint()) return;
    self.available.deinit();
    self.queue.deinit();
}

pub fn _bindMethods() void {
    godot.registerMethod(Self, "play");
}

const Node = godot.class.Node;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const ArrayList = std.ArrayList;
const AudioStream = godot.class.AudioStream;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const ResourceLoader = godot.class.ResourceLoader;
const Engine = godot.class.Engine;

const std = @import("std");
const godot = @import("gdzig");
