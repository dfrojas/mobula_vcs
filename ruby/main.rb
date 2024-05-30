require "digest"
require "find"
require "set"

CONFIG_FILE_NAME = ".mobula_config"

def init
  Dir.mkdir(CONFIG_FILE_NAME) unless Dir.exist?(CONFIG_FILE_NAME)
  puts ("Created #{CONFIG_FILE_NAME} directory")
end

def commit(directory)
  snapshot_hash = Digest::SHA256.new
  snapshot_data = { "files" => {} }

  files = []

  Find.find(directory) do |path|
    if File.file?(path)
      files << path
    end
  end

  files.each do |file|
    if File.join(directory, file).include?(CONFIG_FILE_NAME) or file.include?("main.rb")
      next
    end
    file_path = File.join(file)
    content = File.read(file_path)
    snapshot_hash.update(content)
    snapshot_data["files"][file_path] = content
  end

  hash_digest = snapshot_hash.hexdigest()
  snapshot_data["file_list"] = snapshot_data["files"].keys()

  File.open(File.join(CONFIG_FILE_NAME, hash_digest), "wb") do |f|
    f.write(Marshal.dump(snapshot_data))
  end

  puts "Commit created #{hash_digest}"
end

def revert(commit_hash)
  commit_path = File.join(CONFIG_FILE_NAME, commit_hash)

  if not File.exist?(commit_path)
    puts "Commit not found"
  end

  snapshot_data = nil

  File.open(commit_path, "rb") do |f|
    snapshot_data = Marshal.load(f)

    for file_path, content in snapshot_data["files"]
      unless not File.exist?(file_path)
        File.write(file_path, content)
      end
    end
  end

  files_not_in_commit = Set.new

  Find.find(".") do |path|
    if path.include?(CONFIG_FILE_NAME) or path.include?("main.rb")
      next
    end
    files_not_in_commit.add(path)
  end

  files_in_commit = Set.new(snapshot_data["file_list"])

  files_to_delete = files_not_in_commit - files_in_commit
  files_to_delete.delete(".") # remove the current directory

  files_to_delete.each do |file|
    File.delete(file)
  end

  puts "Reverted to commit #{commit_hash}"
end

if __FILE__ == $0
  command = ARGV[0]
  case command
  when "init"
    init
  when "commit"
    commit(".")
  when "revert"
    revert(ARGV[1])
  else
    puts "Unknown command"
  end
end
