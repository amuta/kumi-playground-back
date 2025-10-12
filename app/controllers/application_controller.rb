class ApplicationController < ActionController::API
  rescue_from StandardError do |e|
    Rails.logger.error("Unhandled error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
    render status: :internal_server_error, json: { ok: false, errors: [e.message] }
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render status: :not_found, json: { ok: false, errors: ["Resource not found"] }
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render status: :unprocessable_entity, json: { ok: false, errors: e.record.errors.full_messages }
  end
end
