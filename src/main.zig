const std = @import("std");

/// Static Allocation
const looking_for: []const u8 = "zig-out";
/// Static Allocation
const known_ignore = &[_][]const u8{
    "node_modules",
    "target",
    ".git",
};
const stdout = std.io.getStdOut();
const writer = stdout.writer();

fn walk(gpa: std.mem.Allocator, paths: *std.ArrayList([]const u8), start: std.fs.Dir, previous: []const u8) !void {
    var it = start.iterate();

    outer: while (try it.next()) |entry| {
        for (known_ignore) |ignore| {
            if (entry.name.len < ignore.len) continue;

            if (std.mem.containsAtLeast(u8, entry.name, 1, ignore)) {
                continue :outer;
            }
        }

        const path_size = previous.len + entry.name.len + "/".len;
        const bytes = try gpa.alloc(u8, path_size);
        // Have to copy the path, because the walker deallocates
        // the memory of the entry automatically once it has been
        // accessed.
        std.mem.copyForwards(u8, bytes, previous);
        std.mem.copyForwards(u8, bytes[previous.len..], "/");
        std.mem.copyForwards(u8, bytes[previous.len + "/".len ..], entry.name);

        if (entry.name.len >= looking_for.len) {
            const end_slice = entry.name[entry.name.len - looking_for.len ..];
            if (std.mem.eql(u8, looking_for, end_slice)) {
                try paths.append(bytes);
            }
        }

        // Ingores dotfiles / dotfolders
        if (entry.kind == .directory and !std.mem.eql(u8, entry.name, looking_for) and entry.name[0] != '.') {
            var sub_dir = try start.openDir(entry.name, .{ .iterate = true, .no_follow = true, .access_sub_paths = false });
            defer sub_dir.close();
            try walk(gpa, paths, sub_dir, bytes);
        }
    }
}

pub fn main() !void {
    var alloc_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = alloc_impl.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .no_follow = true, .access_sub_paths = false });
    var paths: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(gpa);
    defer paths.deinit();

    const thread = try std.Thread.spawn(.{}, walk, .{
        gpa,
        &paths,
        cwd,
        ".",
    });

    // Do other shenanigans here?
    //
    // End shenanigans

    thread.join();

    for (paths.items) |path| {
        try stdout.writer().print("{s}\n", .{path});
    }
}
