module SearchObject
  module Plugin
    module Graphql
      def self.included(base)
        base.extend ClassMethods
      end

      attr_reader :obj, :ctx

      def initialize(filters: {}, obj: nil, ctx: {}, scope: nil)
        @obj = obj
        @ctx = ctx

        super filters: filters, scope: scope
      end

      module ClassMethods
        def call(obj, args, ctx)
          new(filters: args.to_h, obj: obj, ctx: ctx).results
        end

        def option(name, options = nil, &block)
          arguments[name] = options.fetch(:type) { raise 'TODO error class' }

          super
        end

        def types
          GraphQL::Define::TypeDefiner.instance
        end

        def arguments
          config[:args] ||= {}
        end
      end
    end
  end
end

