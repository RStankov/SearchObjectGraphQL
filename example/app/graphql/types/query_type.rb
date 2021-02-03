# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :categories, resolver: Resolvers::CategorySearch
    field :posts, resolver: Resolvers::PostSearch
  end
end
