const std = @import("std");

/// Convert a string slice to a `null` terminated C string
fn toCString(allocator: *const std.mem.Allocator, string: []u8) ![*c]u8 {
    const cString: []u8 = try allocator.realloc(string, string.len + 1);
    cString[string.len] = 0;
    return cString[0..].ptr;
}
