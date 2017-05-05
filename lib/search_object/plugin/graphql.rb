module SearchObject
  module Plugin
    module Graphql
      def self.included(base)
        base.include SearchObject::Plugin::Enum
        base.extend ClassMethods
      end

      attr_reader :object, :context

      def initialize(filters: {}, object: nil, context: {}, scope: nil)
        @object = object
        @context = context

        super filters: filters, scope: scope
      end

      module ClassMethods
        def option(name, options = {}, &block)
          argument = Helper.build_argument(name, options)
          arguments[argument.name] = argument

          options[:enum] = argument.type.values.keys if argument.type.is_a? GraphQL::EnumType

          super(name, options, &block)
        end

        def types
          GraphQL::Define::TypeDefiner.instance
        end

        # NOTE(rstankov): GraphQL::Function interface
        # Documentation - https://rmosolgo.github.io/graphql-ruby/schema/code_reuse#functions
        def call(object, args, context)
          new(filters: args.to_h, object: object, context: context).results
        end

        def arguments
          config[:args] ||= {}
        end

        def type(value = :default, &block)
          return config[:type] if value == :default && !block_given?
          config[:type] = block_given? ? GraphQL::ObjectType.define(&block) : value
        end

        def complexity(value = :default)
          return config[:complexity] || 1 if value == :default
          config[:complexity] = value
        end

        def description(value = :default)
          return config[:description] if value == :default
          config[:description] = value
        end

        def deprecation_reason(value = :default)
          return config[:deprecation_reason] if value == :default
          config[:deprecation_reason] = value
        end
      end

      class MissingTypeDefinitionError < ArgumentError
        def initialize(name)
          super "GraphQL type has to passed as :type to '#{name}' option"
        end
      end

      # :api: private
      module Helper
        module_function

        def build_argument(name, options)
          argument = GraphQL::Argument.new
          argument.name = name.to_s
          argument.type = options.fetch(:type) { raise MissingTypeDefinitionError, name }
          argument.default_value = options[:default] if options.key? :default
          argument.description = options[:description] if options.key? :description
          argument
        end
      end
    end
  end
end
