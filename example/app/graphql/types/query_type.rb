# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :categories, function: Resolvers::CategorySearch
    field :posts, resolver: Resolvers::PostSearch
  end
end
