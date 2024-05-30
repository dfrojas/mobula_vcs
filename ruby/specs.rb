require "rspec"
require_relative "./main"
require "FileUtils"

describe "#init" do
  let(:test_config_dir) { ".mobula_config" }

  after(:each) do
    FileUtils.rm_r(test_config_dir) if Dir.exist?(test_config_dir)
  end

  it "creates the config directory" do
    init()
    expect(Dir.exist?(test_config_dir)).to be true
  end
end

describe "#commit" do
  let(:test_config_dir) { ".mobula_config" }
  let(:test_file) { "test_file.py" }
  let(:test_file_content) { "def hey():\n    pass" }

  before(:each) do
    File.open(File.join(test_file), "w") { |f| f.write(test_file_content) }
  end

  after(:each) do
    FileUtils.rm_r(test_config_dir) if File.exist?(test_config_dir)
    FileUtils.rm_r(test_file) if File.exist?(test_file)
  end

  it "creates a commit" do
    init()
    commit(".")

    created_files = Dir.glob("#{test_config_dir}/*")
    expect(created_files.size).to eq(1)
    expect(File.read(created_files.first)).to include(test_file_content)
  end
end

describe "#revert" do
  let(:test_config_dir) { ".mobula_config" }
  let(:test_file) { "test_file.py" }
  let(:test_file_content) { "def hey():\n    pass" }
  let(:mocked_hash) { "mockedhashvalue1234567890abcdef" }

  before(:each) do
    File.open(File.join(test_file), "w") { |f| f.write(test_file_content) }
  end

  after(:each) do
    FileUtils.rm_r(test_config_dir) if File.exist?(test_config_dir)
    FileUtils.rm_r(test_file) if File.exist?(test_file)
  end

  it "reverts a commit" do
    # TODO
  end
end
