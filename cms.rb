require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
# require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path("..", __FILE__)

# get "/" do
#   @files = Dir.glob(root + "/data/*").map do |path|
#     File.basename(path)
#   end
#   erb :index
# end

get "/" do
  # Find all files in the data directory:
  @files = Dir.glob(root + "/data/*").select do |file|
    File.ftype(file) == "file"
  end.sort

  # Remove prepended directory names:
  @files.map! { |file| File.basename(file) }.sort

  erb :index
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]

  if File.file?(file_path)
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
