Rails.application.routes.draw do
  namespace :api do
    post "kumi/compile",       to: "kumi_compile#create"
    post "share/ephemeral",    to: "shares#ephemeral"
    post "share/public",       to: "shares#public"
    get  "s/:id",              to: "shares#show_ephemeral"
    get  "p/:uid",             to: "shares#show_public"
    get  "kumi/artifacts/:schema_hash.js", to: "artifacts#show"
  end

  get :healthz, to: proc { [200, {"Content-Type"=>"text/plain"}, ["ok"]] }
end
