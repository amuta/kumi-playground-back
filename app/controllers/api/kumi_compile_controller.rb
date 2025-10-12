class Api::KumiCompileController < ActionController::API
  KVER = ENV.fetch("KUMI_COMPILER_VERSION", "1")

  def create
    src = params.require(:schema_src).to_s

    result = KumiCompile.call(src)
    unless result[:ok]
      return render status: :internal_server_error, json: { ok: false, errors: result[:errors] }
    end

    schema_digest = result[:schema_digest]
    key = cache_key(schema_digest)

    js = REDIS.get(key)
    unless js
      js = result[:js_src]
      REDIS.set(key, js)
      REDIS.expire(key, 30.days)
    end

    render json: {
      ok: true,
      schema_hash: schema_digest,
      artifact_url: artifact_url(schema_digest),
      artifact_hash: Digest::SHA256.hexdigest(js),
      js_src: js,
      ruby_src: result[:ruby_src]
    }
  rescue ActionController::ParameterMissing => e
    render status: :bad_request, json: { ok: false, errors: [e.message] }
  end

  private

  def cache_key(digest)
    "kumi:art:v#{KVER}:#{digest}"
  end

  def artifact_url(digest)
    "#{request.base_url}/api/kumi/artifacts/#{digest}.js"
  end
end
