# frozen_string_literal: true

module Types
  class CategoryType < BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :posts, resolver: Resolvers::PostSearch
  end
end
