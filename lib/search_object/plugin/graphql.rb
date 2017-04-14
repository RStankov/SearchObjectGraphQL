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
      end
    end
  end
end
