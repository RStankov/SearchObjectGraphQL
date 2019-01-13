# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :categories, function: Resolvers::CategorySearch
    field :posts, function: Resolvers::PostSearch
  end
end
