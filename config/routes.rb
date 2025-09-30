Rails.application.routes.draw do
  namespace :api do
    post "kumi/compile", to: "kumi#compile"
  end

  get :healthz, to: proc { [200, {"Content-Type"=>"text/plain"}, ["ok"]] }
end
