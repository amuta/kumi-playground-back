class Api::SharesController < ActionController::API
  def ephemeral
    body = request.raw_post.presence || params.to_json
    id   = SecureRandom.urlsafe_base64(6)
    REDIS.setex("kumi:share:#{id}", 7.days, Brotli.deflate(body))
    render json: { url: "#{request.base_url}/api/s/#{id}" }
  rescue Redis::BaseError => e
    render status: :service_unavailable, json: { ok: false, errors: ["Storage service unavailable"] }
  end

  def show_ephemeral
    blob = REDIS.get("kumi:share:#{params[:id]}")
    return head :not_found unless blob
    json = Brotli.inflate(blob)
    send_data json, type: "application/json", filename: "kumi-bundle.json"
  rescue Redis::BaseError => e
    render status: :service_unavailable, json: { ok: false, errors: ["Storage service unavailable"] }
  end

  def public
    body = request.raw_post.presence || params.to_json
    uid  = "PUB_" + SecureRandom.alphanumeric(10)
    PublicShare.create!(uid:, blob: Brotli.deflate(body))
    render json: { url: "#{request.base_url}/api/p/#{uid}" }
  rescue ActiveRecord::RecordInvalid => e
    render status: :unprocessable_entity, json: { ok: false, errors: e.record.errors.full_messages }
  end

  def show_public
    ps = PublicShare.find_by!(uid: params[:uid])
    send_data Brotli.inflate(ps.blob), type: "application/json", filename: "kumi-bundle.json"
  end
end
