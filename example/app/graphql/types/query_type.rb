# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  connection :categories, Types::CategoryType.connection_type, function: Resolvers::CategorySearch

  connection :posts, Types::PostType.connection_type, function: Resolvers::PostSearch
end
