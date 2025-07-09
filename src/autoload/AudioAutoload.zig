const Self = @This();

base: *Node,
num_players: u32 = 12,
bus: StringName,
available: ArrayList(*AudioStreamPlayer) = .empty,
queue: ArrayList(String) = .empty,

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

        var callable = godot.builtin.Callable.initObjectMethod(
            @ptrCast(godot.meta.asObject(self)),
            .fromComptimeLatin1("_onStreamFinished"),
        );
        var args: godot.builtin.Array = .init();
        args.append(.init(player));
        _ = player.connect(.fromComptimeLatin1("finished"), callable.bindv(args), .{});

        self.base.addChild(Node.upcast(player), .{});
        self.available.append(godot.heap.general_allocator, player) catch @panic("Failed to append AudioStreamPlayer to list");
    }
}

pub fn _process(self: *Self, delta: f64) void {
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

const Node = godot.class.Node;
const String = godot.builtin.String;
const StringName = godot.builtin.StringName;
const ArrayList = std.ArrayListUnmanaged;
const AudioStream = godot.class.AudioStream;
const AudioStreamPlayer = godot.class.AudioStreamPlayer;
const ResourceLoader = godot.class.ResourceLoader;
const Engine = godot.class.Engine;
const Variant = godot.builtin.Variant;

const std = @import("std");
const godot = @import("gdzig");
