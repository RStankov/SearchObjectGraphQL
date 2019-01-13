# frozen_string_literal: true

module Resolvers
  class BaseSearchResolver
    include SearchObject.module(:graphql)

    def escape_search_term(term)
      "%#{term.gsub(/\s+/, '%')}%"
    end
  end
end
