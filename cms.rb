require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

VALID_EXTENTIONS = [".md", ".txt"].freeze

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def puts_this(message)
  puts message
end

helpers do

  class Stream
    def each
      100.times { |i| yield "#{i}\n" }
    end
  end

  def load_user_credentials
    credentials_path = if ENV["RACK_ENV"] == "test"
      File.expand_path("../test/users.yml", __FILE__)
    else
      File.expand_path("../users.yml", __FILE__)
    end
    YAML.load_file(credentials_path)
  end

  def valid_credentials?(username, password)
    credentials = load_user_credentials

    if credentials.has_key?(username)
      # bcrypt_decrypted_password = BCrypt::Password.new(credentials[username])

      # bcrypt_decrypted_password == password
      # The line below is the same as the one directly above.
      BCrypt::Password.new(credentials[username]).is_password?(password)

      # password == bcrypt_decrypted_password # This does not work, because
      # BCrypt::Password overrides the == ... See docs.
    else
      false
    end
  end

  def render_markdown(markdown_text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(markdown_text)
  end

  def load_file_content(file_path)
    file_content = File.read(file_path)

    case File.extname(file_path)
    when ".md"
      erb render_markdown(file_content)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      file_content # Notice how text files are not displayed within the layout because the erb method isn't called for them.
    end
  end

  def user_signed_in?
    session.has_key?(:username)
  end

  def require_signed_in_user
    unless user_signed_in?
      session[:message] = "You must be signed in to do that."
      redirect "/"
    end
  end

  def valid_filename?(filename)
    VALID_EXTENTIONS.include?(File.extname(filename))
  end

  def files_array
    # Find all files in the data directory:
    pattern = File.join(data_path, "*")

    files = Dir.glob(pattern).select do |file|
      File.ftype(file) == "file"
    end

    # Remove prepended directory names and any sole directory names:
    files.map! { |file| File.basename(file) }.sort
  end
end

get "/" do
  @files = files_array

  erb :index
end

#  Delete this later!
get('/123') { Stream.new }

get "/new" do
  require_signed_in_user

  erb :new
end

get "/:filename" do
  # get "/view" do # Used to illustrate Security in the course.
  file_path = File.join(data_path, File.basename(params[:filename]))

  # file_path = File.join(data_path, params[:filename])
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/:filename/delete" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted."

  redirect "/"
end

post "/create" do
  require_signed_in_user

  filename = params[:filename].to_s.downcase # Convert to String so the line which checks for zero length filenames works correctly.

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  elsif !valid_filename?(filename)
    session[:message] = "#{filename} does not have a valid file extention."
    status 422
    erb :new
  elsif files_array.include?(filename)
    session[:message] = "The file #{filename} already exists."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{filename} has been created."

    redirect "/"
  end
end

post "/:filename" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been saved/updated."
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  # credentials = load_user_credentials
  username = params[:username]

  # if credentials.key?(username) && credentials[username] == params[:password]
  # if params[:username] == "admin" && params[:password] == "secret"
  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end
