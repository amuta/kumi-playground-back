require "test_helper"

class SpaCacheTest < ActionDispatch::IntegrationTest
  def simple_schema
    "schema do\n  input do\n    string :name\n  end\n  value :name, input.name\nend"
  end

  test "index.html should have no-cache headers for cache invalidation" do
    get "/"

    assert_response :success
    assert response.content_type.include?("text/html")

    cache_control = response.headers["Cache-Control"]
    assert cache_control.include?("no-cache"),
      "Expected 'no-cache' in Cache-Control header, got: #{cache_control}"
  end

  test "index.html should have max-age=0 to prevent caching" do
    get "/"

    cache_control = response.headers["Cache-Control"]
    assert cache_control.include?("max-age=0"),
      "Expected 'max-age=0' to disable caching, got: #{cache_control}"
  end

  test "API routes are not affected by cache headers" do
    post "/api/kumi/compile", params: { schema_src: simple_schema }, as: :json
    assert_response :success
    # Should get JSON response, not HTML
    assert response.content_type.include?("application/json")
  end
end
