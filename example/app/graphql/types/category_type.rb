# frozen_string_literal: true

module Types
  class CategoryType < BaseObject
    field :id, ID, null: false
    field :name, String, null: false

    field :posts, PostType.connection_type, null: false, function: Resolvers::PostSearch
  end
end
