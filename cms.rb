require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

get "/" do
  # Find all files in the data directory:
  @files = Dir.glob(root + "/data/*").select do |file|
    File.ftype(file) == "file"
  end

  # Remove prepended directory names:
  @files.map! { |file| File.basename(file) }.sort

  # @files = Dir.glob(root + "/data/*").map do |path|
  #   File.basename(path)
  # end
  erb :index
end
