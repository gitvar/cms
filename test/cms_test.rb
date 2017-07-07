ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content="")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  # Tests to follow:
  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<title>CMS</title>"
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_viewing_document
    create_document "history.txt", "Ruby 0.95 released"

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end

  def test_document_not_found
    get "/notafile.ext"
    assert_equal 302, last_response.status

    get last_response["Location"] # http://localhost:4567/ see 'Inspect Element'
    # Above is equal to: get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"
  end

  def test_viewing_markdown_document
    create_document "about.md", "# About Ruby:"

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>About Ruby:</h1>"
  end

  def test_editing_document
    create_document "changes.txt" #, "#{%Q(<textarea name="content")}"

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %Q(<textarea name="content")
  end

  def test_updating_document
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status
    # Testing on the Firefox browser gives a last response status of 303 when saving. Guess it is different when tests are run and server is not being used. Both 302 and 303 indicates 'redirection' so it is basically the same thing...
    # "new content" is not appended, but saved over previous content1!

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "changes.txt has been saved/updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post "/create", filename: "test.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been created"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/create", filename: ""

    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_delete_document
    create_document "test_document.txt"

    post "/test_document.txt/delete"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test_document.txt has been deleted"

    get "/"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "test_document.txt"
  end

  def test_sign_in_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(name="username")
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_sign_in_with_correct_credentials
    post "/users/signin", username: "admin", password: "secret"

    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Welcome!"
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_sign_in_with_bad_credentials
    # post "/users/signin", username: "admin", password: "wrong"
    #
    # assert_equal 302, last_response.status
    # get last_response["Location"]
    # assert_includes last_response.body, "Invalid Credentials"
    # assert_includes last_response.body, %q(name="username")
    # assert_includes last_response.body, %q(<button type="submit")
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_sign_out
    post "/users/signin", username: "admin", password: "secret"
    get last_response["Location"]
    assert_includes last_response.body, "Welcome"

    post "/users/signout"
    get last_response["Location"]
    assert_includes last_response.body, "You have been signed out"
    assert_includes last_response.body, "Sign In"

  end
end
