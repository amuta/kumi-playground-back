class SpaCacheHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    # Set proper cache headers for index.html
    # This ensures index.html is never cached, enabling cache invalidation on deploys
    path = env['PATH_INFO'] || env['REQUEST_URI'] || ''

    if path == '/' || path.end_with?('index.html')
      headers['Cache-Control'] = 'public, no-cache, max-age=0'
      headers['Pragma'] = 'no-cache'
      headers['Expires'] = '0'
    end

    [status, headers, body]
  end
end
