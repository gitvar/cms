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
      erb render_markdown(file_content)
    else
      headers["Content-Type"] = "text/plain"
      file_content # Notice how text files are not displayed within the layout because the erb method isn't called for them.
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

get "/new" do
  erb :new
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

post "/:filename/delete" do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted."

  redirect "/"
end

post "/create" do
  filename = params[:filename].to_s # Makes the line below work correctly.

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been saved/updated."
  redirect "/"
end
