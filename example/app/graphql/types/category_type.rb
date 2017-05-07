Types::CategoryType = GraphQL::ObjectType.define do
  name 'Category'

  field :id, !types.ID
  field :name, !types.String

  connection :posts, Types::PostType.connection_type, function: Resolvers::PostSearch
end
