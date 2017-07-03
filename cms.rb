require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
# require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

# root = File.expand_path("..", __FILE__)
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

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

get "/" do
  # Find all files in the data directory:
  pattern = File.join(data_path, "*")

  @files = Dir.glob(pattern).select do |file|
    File.ftype(file) == "file"
  end

  # Remove prepended directory names and any sole directory names:
  @files.map! { |file| File.basename(file) }.sort

  erb :index
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been saved/updated."
  redirect "/"
end
