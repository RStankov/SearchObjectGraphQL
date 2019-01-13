# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :categories, CategoryType.connection_type, null: false, function: Resolvers::CategorySearch
    field :posts, PostType.connection_type, null: false, function: Resolvers::PostSearch
  end
end
