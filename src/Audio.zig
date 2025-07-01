const Self = @This();

base: Node,
allocator: Allocator,
num_players: u32 = 12,
bus: StringName = undefined,
available: ArrayList(AudioStreamPlayer) = .empty,
queue: ArrayList(String) = .empty,

pub fn _ready(self: *Self) void {
    self.allocator = godot.heap.general_allocator;
    self.bus = .fromComptimeLatin1("master");

    for (0..self.num_players) |_| {
        var player: AudioStreamPlayer = .init();
        player.setVolumeDb(-10);
        player.setBus(self.bus);

        godot.connect(player, "finished", self, "onStreamFinished");
        self.base.addChild(Node.upcast(player), .{});
        self.available.append(self.allocator, player) catch unreachable;
    }
}

pub fn _process(self: *Self, delta: f32) void {
    _ = delta; // autofix
    if (self.queue.items.len > 0 and self.available.items.len > 0) {
        var player = self.available.swapRemove(0);
        const stream = AudioStream.downcast(ResourceLoader.load(self.queue.swapRemove(0), .{}).?) catch unreachable;
        player.setStream(stream);
        player.setPitchScale(@floatCast(godot.random.randfRange(0.9, 1.1)));
        player.play(.{});
    }
}

pub fn onStreamFinished(self: *Self, args: *struct { AudioStreamPlayer }) void {
    self.available.append(self.allocator, args.@"0") catch unreachable;
}

pub fn play(self: *Self, sound_path: String) void {
    self.queue.append(self.allocator, sound_path) catch unreachable;
}

pub fn deinit(self: *Self) void {
    self.available.deinit(self.allocator);
}

const Node = godot.class.Node;
const String = godot.builtin.String;
const Allocator = std.mem.Allocator;
const Variant = godot.builtin.Variant;
const StringName = godot.builtin.StringName;
const ArrayList = std.ArrayListUnmanaged;
const AudioStream = godot.class.AudioStream;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const ResourceLoader = godot.class.ResourceLoader;

const std = @import("std");
const godot = @import("gdzig");
