class Api::ArtifactsController < ActionController::API
  KVER = ENV.fetch("KUMI_COMPILER_VERSION", "1")

  def show
    digest = params[:schema_hash]
    key = "kumi:art:v#{KVER}:#{digest}"
    js = REDIS.get(key)
    return head :not_found unless js

    expires_in 1.year, public: true
    response.set_header "Cache-Control", "public, max-age=31536000, immutable"
    send_data js, type: "text/javascript", disposition: "inline"
  end
end
