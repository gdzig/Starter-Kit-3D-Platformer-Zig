const Self = @This();

base: *Node,
num_players: u32 = 12,
bus: StringName,
available: ArrayList(*AudioStreamPlayer) = .empty,
queue: ArrayList(String) = .empty,

pub fn getAutoload(tree: ?*SceneTree) *Self {
    return godot.object.downcast(
        *Self,
        tree.?.getRoot().?.getNode(.fromString(.fromLatin1("/root/Audio"))).?,
    ).?;
}

pub fn init(base: *Node) Self {
    return .{
        .base = base,
        .bus = .fromComptimeLatin1("master"),
    };
}

pub fn _ready(self: *Self) void {
    if (Engine.isEditorHint()) return;

    for (0..self.num_players) |_| {
        var player = AudioStreamPlayer.init();
        player.setVolumeDb(-10);
        player.setBus(self.bus);

        var args: godot.builtin.Array = .init();
        args.append(.init(player));

        var callable = Callable.fromClosure(self, &_onStreamFinished);
        defer callable.deinit();

        var bound_callable = callable.bindv(args);
        defer bound_callable.deinit();

        godot.connect(player, AudioStreamPlayer.FinishedSignal, bound_callable);

        self.base.addChild(Node.upcast(player), .{});
        self.available.append(godot.heap.general_allocator, player) catch @panic("Failed to append AudioStreamPlayer to list");
    }
}

pub fn _process(self: *Self, delta: f64) void {
    if (Engine.isEditorHint()) return;

    _ = delta;

    if (self.queue.items.len > 0 and self.available.items.len > 0) {
        var player = self.available.swapRemove(0);
        const stream = AudioStream.downcast(ResourceLoader.load(self.queue.swapRemove(0), .{}).?).?;
        player.setStream(stream);
        player.setPitchScale(@floatCast(godot.random.randfRange(0.9, 1.1)));
        player.play(.{});
    }
}

pub fn _onStreamFinished(self: *Self, player: *AudioStreamPlayer) void {
    self.available.append(godot.heap.general_allocator, player) catch @panic("Failed to append AudioStreamPlayer to available list");
}

pub fn play(self: *Self, sound_path: String) void {
    self.queue.append(godot.heap.general_allocator, sound_path) catch unreachable;
}

pub fn _exitTree(self: *Self) void {
    if (Engine.isEditorHint()) return;
    self.available.deinit(godot.heap.general_allocator);
    self.queue.deinit(godot.heap.general_allocator);
}

pub fn _bindMethods() void {
    godot.registerMethod(Self, "play");
    godot.registerMethod(Self, "_onStreamFinished");
}

const godot = @import("gdzig");
const ArrayList = std.ArrayListUnmanaged;
const AudioStream = godot.class.AudioStream;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const Callable = godot.builtin.Callable;
const Engine = godot.class.Engine;
const Node = godot.class.Node;
const ResourceLoader = godot.class.ResourceLoader;
const SceneTree = godot.class.SceneTree;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const Variant = godot.builtin.Variant;

const std = @import("std");
