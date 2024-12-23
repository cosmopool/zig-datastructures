const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

pub fn RingBuffer(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        items: [size]T,
        head: usize = 0,
        writeIdx: usize = 0,
        full: bool = false,

        /// The ring buffer will be allocated in the stack
        /// so no manual deinit() is required.
        pub fn init() Self {
            return Self{ .items = undefined };
        }

        /// Set `position` to the next valid array position.
        /// If we are at the end of the array, `position` will start
        /// again at the begining.
        pub fn updateTailPosition(self: *Self) void {
            assert(self.writeIdx <= size);
            self.writeIdx = (self.writeIdx + 1) % size;

            if (self.writeIdx == self.head and !self.full) self.full = true;

            if (!self.full) {
                assert(self.head == 0);
                return;
            }

            self.head = self.writeIdx;
        }

        /// Insert a new element in this RingBuffer
        /// Will replace the item if no empty position is available
        pub fn insert(self: *Self, item: T) void {
            self.items[self.writeIdx] = item;
            self.updateTailPosition();
        }

        pub fn elementAt(self: Self, index: usize) ?T {
            if (index >= size) return self.items[index];
            if (self.head == 0 and self.writeIdx == 0 and !self.full) return null;

            return self.items[(index + self.head) % size];
        }
    };
}

test "init" {
    const buffer = try RingBuffer(i32, 3).init(testing.allocator);

    try testing.expect(buffer.items.len == 3);
    try testing.expect(buffer.writeIdx == 0);
    try testing.expect(buffer.head == 0);
}

test "insert" {
    var buffer = try RingBuffer(i32, 3).init(testing.allocator);

    buffer.insert(1);
    buffer.insert(2);
    buffer.insert(3);
    try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 1, 2, 3 }));

    buffer.insert(0);
    try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 2, 3 }));

    buffer.insert(1);
    try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 1, 3 }));

    buffer.insert(2);
    try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 1, 2 }));

    buffer.insert(3);
    try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 3, 1, 2 }));
}

test "head" {
    var buffer = try RingBuffer(i32, 3).init(testing.allocator);

    buffer.insert(1);
    try testing.expect(buffer.head == 0);
    buffer.insert(2);
    try testing.expect(buffer.head == 0);
    buffer.insert(3);
    try testing.expect(buffer.head == 0);

    buffer.insert(0);
    try testing.expect(buffer.head == 1);

    buffer.insert(1);
    try testing.expect(buffer.head == 2);

    buffer.insert(2);
    try testing.expect(buffer.head == 0);

    buffer.insert(3);
    try testing.expect(buffer.head == 1);
}

test "retrieve elements" {
    var buffer = try RingBuffer(i32, 3).init(testing.allocator);

    // with no element
    try testing.expect(buffer.elementAt(0) == null);
    try testing.expect(buffer.elementAt(1) == null);
    try testing.expect(buffer.elementAt(2) == null);

    buffer.insert(1);
    try testing.expect(buffer.elementAt(0) == 1);
    buffer.insert(2);
    try testing.expect(buffer.elementAt(1) == 2);
    buffer.insert(3);
    try testing.expect(buffer.elementAt(2) == 3);
    buffer.insert(0);
    try testing.expect(buffer.elementAt(2) == 0);
}
