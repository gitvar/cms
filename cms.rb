require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
# require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path("..", __FILE__)

helpers do
  def render_markdown(markdown_text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(markdown_text)
  end

  def load_file_content(file_path)
    file_content = File.read(file_path)

    case File.extname(file_path)
    when ".md"
      render_markdown(file_content)
    else
      headers["Content-Type"] = "text/plain"
      file_content
    end
  end
end

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
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
