# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    def initialize(*args, permission: true, **kwargs, &block)
      super(*args, **kwargs, &block)

      raise GraphQL::ExecutionError, 'No permission' unless permission
    end
  end
end
