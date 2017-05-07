Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: '/', graphql_path: '/graphql'

  post "/graphql", to: "graphql#execute"
end
