const std = @import("std");
const json = std.json;
const fs = std.fs;
const sha256 = std.crypto.hash.sha2.Sha256;

const CONFIG_FILE_NAME = ".mobula_config";

pub fn init(directory: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const cwd = fs.cwd();
    const path = try std.fmt.allocPrint(arena_allocator, "{s}/{s}", .{ directory, CONFIG_FILE_NAME });

    cwd.makeDir(path) catch |err| {
        if (err == error.PathAlreadyExists) {
            std.debug.print("Repository already initialized\n", .{});
            return;
        }
        return err;
    };
    std.debug.print("Mobula VCS initialized\n", .{});
}

const CommitData = struct {
    files: std.StringHashMap([]const u8),
    files_list: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) CommitData {
        return CommitData{
            .files = std.StringHashMap([]const u8).init(allocator),
            .files_list = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *CommitData) void {
        self.files.deinit();
        self.files_list.deinit();
    }

    pub fn jsonStringify(self: CommitData, jw: anytype) !void {
        // I'm following the implementation of jsonStringify of HashMap
        // to Jsonfy the CommitData structure.
        // https://github.com/ziglang/zig/blob/master/lib/std/json/hashmap.zig#L65
        // https://ziggit.dev/t/how-to-stringify-complex-struct/6511/6
        try jw.beginObject();

        try jw.objectField("files");
        try jw.beginObject();
        var it = self.files.iterator();
        while (it.next()) |kv| {
            try jw.objectField(kv.key_ptr.*);
            try jw.write(kv.value_ptr.*);
        }
        try jw.endObject();

        try jw.objectField("files_list");
        try jw.write(self.files_list.items);

        try jw.endObject();
    }
};

fn readFile(allocator: std.mem.Allocator, full_path: []const u8) ![]const u8 {
    const file = std.fs.cwd().openFile(full_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("File not found: {s}\n", .{full_path});
            return &[_]u8{};
        } else {
            return err;
        }
    };
    defer file.close();

    // Get the file size to allocate a more accurate space.
    const file_size = try file.getEndPos();
    // Allocate a buffer of the exact file size.
    const buffer = try allocator.alloc(u8, file_size);

    _ = try file.readAll(buffer);

    return buffer;
}

pub fn commit(directory: []const u8) !void {
    var hasher = sha256.init(.{});

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();

    var arena = std.heap.ArenaAllocator.init(general_purpose_allocator.allocator());
    const arena_allocator = arena.allocator();
    defer _ = arena.deinit();

    var commit_data = CommitData.init(arena_allocator);
    defer commit_data.deinit();

    var iterable = try std.fs.cwd().openDir(directory, .{ .iterate = true });
    defer iterable.close();

    var walker = try iterable.walk(arena_allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.indexOf(u8, entry.path, CONFIG_FILE_NAME) != null) {
            continue;
        }

        const full_path = try std.fs.path.join(arena_allocator, &[_][]const u8{ directory, entry.basename });

        // Read the content of file and update the initialized hash with the content of the file.
        const file_contents = try readFile(arena_allocator, full_path);
        hasher.update(file_contents);

        try commit_data.files.put(full_path, file_contents);
        try commit_data.files_list.append(full_path);
    }

    var hash_result: [sha256.digest_length]u8 = undefined;
    hasher.final(&hash_result);
    const hash_str = try std.fmt.allocPrint(arena_allocator, "{s}", .{std.fmt.fmtSliceHexLower(&hash_result)});

    const config_path = try std.fs.path.join(arena_allocator, &[_][]const u8{ directory, CONFIG_FILE_NAME });
    const config_dir = try std.fs.cwd().openDir(config_path, .{});
    const file = try config_dir.createFile(hash_str, .{});

    var buf = std.ArrayList(u8).init(arena_allocator);
    defer buf.deinit();

    try json.stringify(commit_data, .{}, buf.writer());

    _ = try file.write(buf.items);
    defer file.close();

    std.debug.print("Commit created with hash: {s}\n", .{hash_str});
}

pub fn revert(directory: []const u8, commit_hash: []const u8) !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();

    var arena = std.heap.ArenaAllocator.init(general_purpose_allocator.allocator());
    const arena_allocator = arena.allocator();
    defer _ = arena.deinit();

    const commit_path = try std.fs.path.join(arena_allocator, &[_][]const u8{ directory, CONFIG_FILE_NAME, commit_hash });

    const commit_info = readFile(arena_allocator, commit_path) catch |err| {
        if (err == error.FileNotFound) {
            return error.FileNotFound;
        }
        return err;
    };

    // https://github.com/ziglang/zig/blob/a63f7875f451bda975ddabcc0c1feed10a216516/lib/std/json/static.zig#L69-L88
    const parsed_commit_info = try std.json.parseFromSliceLeaky(std.json.Value, arena_allocator, commit_info, .{});
    // defer pased_commit_info.deinit();

    if (parsed_commit_info.object.get("files")) |files_obj| {
        if (files_obj == .object) {
            var files_iterator = files_obj.object.iterator();

            while (files_iterator.next()) |entry| {
                const file_path = entry.key_ptr.*;
                var file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
                defer file.close();
                try file.writeAll(entry.value_ptr.*.string);
            }
        }
    }

    // We essentialy needs a HashSet here, but since the standard library of Zig
    // still does not has this data structure, I opted by creating a HashMap of
    // strings of nulls: {"file_path": null}. The other option is to use the external
    // librasy ziglang-set but I do not want to use external dependencies for this project
    var current_files = std.StringHashMap(void).init(arena_allocator);

    var iterable = try std.fs.cwd().openDir(directory, .{ .iterate = true });
    defer iterable.close();

    var walker = try iterable.walk(arena_allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.indexOf(u8, entry.path, CONFIG_FILE_NAME) != null) {
            continue;
        }
        // We need to create a copy of the memory for each entry to avoid overwrittings.
        // TODO: Blog this.
        const full_path = try std.fmt.allocPrint(arena_allocator, "{s}/{s}", .{ directory, entry.path });
        const path_copy = try arena_allocator.dupe(u8, full_path);
        try current_files.put(path_copy, {});
    }

    var snapshot_files = std.StringHashMap(void).init(arena_allocator);
    if (parsed_commit_info.object.get("files_list")) |files_list_obj| {
        if (files_list_obj == .array) {
            for (files_list_obj.array.items) |file_path_json| {
                if (file_path_json == .string) {
                    try snapshot_files.put(file_path_json.string, {});
                }
            }
        }
    }

    var files_to_delete = std.StringArrayHashMap(void).init(arena_allocator);
    var current_iterator = current_files.iterator();

    while (current_iterator.next()) |entry| {
        const file_path = entry.key_ptr.*;
        if (!snapshot_files.contains(file_path)) {
            try files_to_delete.put(file_path, {});
        }
    }

    var delete_iterator = files_to_delete.iterator();
    while (delete_iterator.next()) |entry| {
        std.debug.print("Files to delete {s}\n", .{entry.key_ptr.*});
    }

    std.debug.print("Reverted to commit {s}\n", .{commit_hash});
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();

    var arena = std.heap.ArenaAllocator.init(general_purpose_allocator.allocator());
    const arena_allocator = arena.allocator();
    defer _ = arena.deinit();

    const args = try std.process.argsAlloc(arena_allocator);

    if (args.len < 4) {
        std.debug.print("No command provided\n", .{});
        return;
    }

    const command = args[1]; // init, commit or revert
    const directory = args[3];

    if (std.mem.eql(u8, command, "init")) {
        try init(directory);
    } else if (std.mem.eql(u8, command, "commit")) {
        try commit(directory);
    } else if (std.mem.eql(u8, command, "revert")) {
        const hash = args[2];
        const revert_directory = args[4];
        try revert(revert_directory, hash);
    }
}
