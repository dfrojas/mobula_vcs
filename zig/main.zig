const std = @import("std");
const fs = std.fs;

const CONFIG_FILE_NAME = ".mobula_config";

pub fn main() !void {
    _ = try fs.cwd().makeOpenPath(CONFIG_FILE_NAME, .{});
    std.debug.print("Config created successfully\n", .{});
    //fs.Dir.makeDir(config_dir_path, ".") catch fs.Dir.makeDir(config_dir_path, ".");
    // try fs.Dir.makeDir(config_dir_path, ".") catch |err| switch (err) {
    //     error.PathAlreadyExists => {
    //         std.debug.print("Directory created successfully\n", .{});
    //     },
    //     else => std.debug.print("Directory created successfully\n", .{}),
    // };
}
