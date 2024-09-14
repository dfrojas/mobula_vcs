const std = @import("std");
const clap = @import("clap");

const fs = std.fs;

const CONFIG_FILE_NAME = ".mobula_config";

pub fn main() !void {
    const args_no_alloc_iter = std.process.args();
    // std.debug.print("Directory created successfully\n", .{args_no_alloc_iter});
    std.debug.print("binary: {s}\n", .{args_no_alloc_iter.next().?});
    // Then the rest are the actual args passed to the program.
    // var i: usize = 1;
    // while (args_no_alloc_iter.next()) |arg| : (i += 1) std.debug.print("arg #{}: {s}\n", .{ i, arg });

    // // On Windows, you need an allocator. :-/
    // var buffer: [1024]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // std.debug.print("\nAlloc:\n", .{});
    // var args_alloc_iter = try std.process.argsWithAllocator(allocator);
    // // Since we're allocating, we need to free resources
    // // when finished.
    // defer args_alloc_iter.deinit();

    // // Then, same as above.
    // std.debug.print("binary: {s}\n", .{args_alloc_iter.next().?});
    // i = 1;
    // while (args_alloc_iter.next()) |arg| : (i += 1) std.debug.print("arg #{}: {s}\n", .{ i, arg });
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // std.process.argsWithAllocator(arena);
    // defer arena.deinit();

    // _ = try fs.cwd().makeOpenPath(CONFIG_FILE_NAME, .{});
    // std.debug.print("Config created successfully\n", .{});
    //fs.Dir.makeDir(config_dir_path, ".") catch fs.Dir.makeDir(config_dir_path, ".");
    // try fs.Dir.makeDir(config_dir_path, ".") catch |err| switch (err) {
    //     error.PathAlreadyExists => {
    //         std.debug.print("Directory created successfully\n", .{});
    //     },
    //     else => std.debug.print("Directory created successfully\n", .{}),
    // };
}
