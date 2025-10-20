class SpaCacheHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    path = env['PATH_INFO'] || env['REQUEST_URI'] || ''

    if path == '/' || path.end_with?('index.html')
      # Never cache index.html - forces browser to check for new version on every visit
      # This enables cache invalidation on deploys
      headers['Cache-Control'] = 'public, no-cache, max-age=0'
      headers['Pragma'] = 'no-cache'
      headers['Expires'] = '0'
    elsif path.include?('-') && (path.end_with?('.js') || path.end_with?('.css') || path.end_with?('.woff2'))
      # Cache hashed assets (index-ABC123.js) for 1 week since they never change
      one_week = 7 * 24 * 60 * 60
      headers['Cache-Control'] = "public, max-age=#{one_week}, immutable"
    end

    [status, headers, body]
  end
end
