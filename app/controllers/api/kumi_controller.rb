class Api::KumiController < ActionController::API
  def compile
    src = params.require(:schema_src).to_s
    result = KumiCompile.call(src)

    if result[:ok]
      render json: { ok: true, js_src: result[:js_src] }
    else
      render status: :internal_server_error, json: { ok: false, errors: result[:errors] }
    end
  rescue ActionController::ParameterMissing => e
    render status: :bad_request, json: { ok: false, errors: [e.message] }
  end
end
