# frozen_string_literal: true

module SearchObject
  module Plugin
    module Graphql
      def self.included(base)
        raise NotIncludedInResolverError, base unless base.ancestors.include? GraphQL::Schema::Resolver
        base.include SearchObject::Plugin::Enum
        base.extend ClassMethods
      end

      attr_reader :object, :context

      def initialize(filters: {}, object: nil, context: {}, scope: nil, field: nil)
        @object = object
        @context = context

        super filters: filters, scope: scope, field: field
      end

      # NOTE(rstankov): GraphQL::Schema::Resolver interface
      # Documentation - http://graphql-ruby.org/fields/resolvers.html#using-resolver
      def resolve_with_support(args = {})
        self.params = args.to_h
        results
      end

      module ClassMethods
        KEYS = %i[type default description required camelize].freeze
        def option(name, options = {}, &block)
          config[:arguments] ||= {}
          config[:arguments][name.to_s] = KEYS.inject({}) do |acc, key|
            acc[key] = options[key] if options.key?(key)
            acc
          end

          type = options.fetch(:type) { raise MissingTypeDefinitionError, name }
          options[:enum] = type.values.map { |value, enum_value| enum_value.value || value } if type.respond_to?(:values)

          super(name, options, &block)
        end

        def type(value = :default, null: true, &block)
          return config[:type] if value == :default && !block_given?

          config[:type] = block_given? ? Class.new(GraphQL::Schema::Object, &block) : value
          config[:null] = null
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

        def types
          GraphQL::Define::TypeDefiner.instance
        end

        # NOTE(rstankov): Used for GraphQL::Schema::Resolver
        def field_options
          {
            type: type,
            description: description,
            extras: [],
            resolver_method: :resolve_with_support,
            resolver_class: self,
            deprecation_reason: deprecation_reason,
            arguments: (config[:arguments] || {}).inject({}) do |acc, (name, options)|
              if options.fetch(:camelize) { true }
                name = name.to_s.split('_').map(&:capitalize).join
                name[0] = name[0].downcase
              end

              acc[name] = ::GraphQL::Schema::Argument.new(
                name: name.to_s,
                type: options.fetch(:type) { raise MissingTypeDefinitionError, name },
                description: options[:description],
                required: !!options[:required],
                camelize: !!options[:camelize],
                default_value: options.fetch(:default) { ::GraphQL::Schema::Argument::NO_DEFAULT },
                owner: self
              )
              acc
            end,
            null: !!config[:null],
            complexity: complexity
          }
        end
      end

      class NotIncludedInResolverError < ArgumentError
        def initialize(base)
          super "#{base.name} should inherit from GraphQL::Schema::Resolver. Current ancestors #{base.ancestors}"
        end
      end

      class MissingTypeDefinitionError < ArgumentError
        def initialize(name)
          super "GraphQL type has to passed as :type to '#{name}' option"
        end
      end
    end
  end
end
