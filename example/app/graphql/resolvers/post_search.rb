# frozen_string_literal: true

module Resolvers
  class PostSearch < Resolvers::BaseSearchResolver
    type Types::PostType.connection_type
    description 'Lists posts'

    class OrderEnum < Types::BaseEnum
      graphql_name 'PostOrder'

      value 'RECENT'
      value 'VIEWS'
      value 'LIKES'
      value 'COMMENTS'
    end

    scope { object.respond_to?(:posts) ? object.posts : Post.all }

    option :id, type: types.String, with: :apply_id_filter
    option :title, type: types.String, with: :apply_title_filter
    option :body, type: types.String, with: :apply_body_filter
    option :categoryId, type: types.String, with: :apply_category_id_filter
    option :categoryName, type: types.String, with: :apply_category_name_filter
    option :published, type: types.Boolean, with: :apply_published_filter
    option :order, type: OrderEnum, default: 'RECENT'

    def apply_id_filter(scope, value)
      scope.where id: value
    end

    def apply_title_filter(scope, value)
      scope.where 'title LIKE ?', escape_search_term(value)
    end

    def apply_body_filter(scope, value)
      scope.where 'body LIKE ?', escape_search_term(value)
    end

    def apply_category_id_filter(scope, value)
      scope.where category_id: value
    end

    def apply_category_name_filter(scope, value)
      scope.joins(:category).where 'categories.name LIKE ?', escape_search_term(value)
    end

    def apply_published_filter(scope, value)
      if value
        scope.published
      else
        scope.unpublished
      end
    end

    def apply_order_with_recent(scope)
      scope.order Arel.sql('published_at IS NOT NULL'), published_at: :desc
    end

    def apply_order_with_views(scope)
      scope.order 'views_count DESC'
    end

    def apply_order_with_likes(scope)
      scope.order 'likes_count DESC'
    end

    def apply_order_with_comments(scope)
      scope.order 'comments_count DESC'
    end
  end
end
