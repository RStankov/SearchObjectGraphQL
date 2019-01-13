# frozen_string_literal: true

Types::PostType = GraphQL::ObjectType.define do
  name 'Post'

  field :id, !types.ID
  field :title, !types.String
  field :body, !types.String
  field :category, !Types::CategoryType
  field :viewsCount, !types.Int, property: :views_count
  field :likesCount, !types.Int, property: :likes_count
  field :commentsCount, !types.Int, property: :comments_count
  field :isPublished, !types.Boolean, property: :published?
  field :publishedAt, !Types::DateTimeType, property: :published_at
end
