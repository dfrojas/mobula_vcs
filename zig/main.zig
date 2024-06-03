const std = @import("std");
const fs = std.fs;

const CONFIG_FILE_NAME = ".mobula_config";

pub fn main() !void {
    const config_dir_path = try fs.cwd().makeOpenPath(CONFIG_FILE_NAME, .{});
    try fs.Dir.makeDir(config_dir_path, ".");
    // if (err == fs.Error.PathAlreadyExists) {
    //     std.debug.print("Config file already exists\n", .{});
    //     return;
    // }
    // return err;

    std.debug.print("Congif directory created\n", .{});
}
