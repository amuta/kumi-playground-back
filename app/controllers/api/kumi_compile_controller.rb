class Api::KumiCompileController < ActionController::API
  KVER = ENV.fetch("KUMI_COMPILER_VERSION", "1")

  def create
    src = params.require(:schema_src).to_s
    src_hash = Digest::SHA256.hexdigest(src)
    compile_cache_key = "kumi:compile:v#{KVER}:#{src_hash}"

    cached_result = REDIS.get(compile_cache_key)
    if cached_result
      result = JSON.parse(cached_result, symbolize_names: true)
    else
      result = KumiCompile.call(src)
      unless result[:ok]
        return render status: :internal_server_error, json: { ok: false, errors: result[:errors] }
      end

      REDIS.set(compile_cache_key, result.to_json)
      REDIS.expire(compile_cache_key, 30.days)

      schema_digest = result[:schema_digest]
      artifact_cache_key = cache_key(schema_digest)
      js = result[:js_src]
      REDIS.set(artifact_cache_key, js)
      REDIS.expire(artifact_cache_key, 30.days)
    end

    schema_digest = result[:schema_digest]
    js = result[:js_src]

    render json: {
      ok: true,
      schema_hash: schema_digest,
      artifact_url: artifact_url(schema_digest),
      artifact_hash: Digest::SHA256.hexdigest(js),
      js_src: js,
      ruby_src: result[:ruby_src],
      lir: result[:lir],
      input_form_schema: result[:input_form_schema],
      output_schema: result[:output_schema]
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
