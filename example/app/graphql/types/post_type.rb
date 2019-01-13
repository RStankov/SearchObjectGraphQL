# frozen_string_literal: true

module Types
  class PostType < BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :body, String, null: false
    field :category, CategoryType, null: false
    field :views_count, Int, null: false
    field :likes_count, Int, null: false
    field :comments_count, Int, null: false
    field :is_published, Boolean, null: false, method: :published?
    field :published_at, DateTimeType, null: false
  end
end
