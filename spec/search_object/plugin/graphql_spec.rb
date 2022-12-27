# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'ostruct'
require 'search_object/plugin/graphql'

Post = Struct.new(:id) do
  def to_json(_options = {})
    { 'id' => id }
  end
end

class PostType < GraphQL::Schema::Object
  field :id, ID, null: false
end

describe SearchObject::Plugin::Graphql do
  def define_schema(&block)
    argument_type = Class.new(GraphQL::Schema::Argument) do
      def initialize(*args, permission: true, **kwargs, &block)
        super(*args, **kwargs, &block)

        raise 'No permission' unless permission
      end
    end

    field_type = Class.new(GraphQL::Schema::Field) do
      argument_class argument_type
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      field_class field_type
      graphql_name 'Query'

      instance_eval(&block)
    end

    Class.new(GraphQL::Schema) do
      query query_type

      max_complexity 1000
    end
  end

  def define_search_class(&block)
    argument_type = Class.new(GraphQL::Schema::Argument) do
      def initialize(*args, permission: true, **kwargs, &block)
        super(*args, **kwargs, &block)

        raise 'No permission' unless permission
      end
    end

    Class.new(GraphQL::Schema::Resolver) do
      argument_class argument_type
      include SearchObject.module(:graphql)

      scope { [] }

      instance_eval(&block) if block_given?
    end
  end

  def define_search_class_and_return_schema(&block)
    search_object = define_search_class(&block)

    define_schema do
      if search_object.type.nil?
        field :posts, [PostType], resolver: search_object
      else
        field :posts, resolver: search_object
      end
    end
  end

  it 'requires class to inherit from GraphQL::Schema::Resolver' do
    expect do
      Class.new { include SearchObject.module(:graphql) }
    end.to raise_error SearchObject::Plugin::Graphql::NotIncludedInResolverError
  end

  it 'can be used as GraphQL::Schema::Resolver' do
    post_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Post'

      field :id, GraphQL::Types::ID, null: false
    end

    search_object = define_search_class do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      type [post_type], null: 1

      option(:id, type: GraphQL::Types::ID) { |scope, value| scope.select { |p| p.id == value } }
    end

    schema = define_schema do
      field :posts, resolver: search_object
    end

    result = schema.execute '{ posts(id: "2") { id } }'

    expect(result).to eq(
      'data' => {
        'posts' => [Post.new('2').to_json]
      }
    )
  end

  it 'can access to parent object' do
    search_object = define_search_class do
      scope { object.posts }
    end

    parent_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Parent'

      field :posts, [PostType], resolver: search_object
    end

    schema = define_schema do
      field :parent, parent_type, null: false
    end

    root = OpenStruct.new(parent: OpenStruct.new(posts: [Post.new('from_parent')]))

    result = schema.execute '{ parent { posts { id }  } }', root_value: root

    expect(result).to eq(
      'data' => {
        'parent' => {
          'posts' => [Post.new('from_parent').to_json]
        }
      }
    )
  end

  it 'can access to context object' do
    schema = define_search_class_and_return_schema do
      scope { [Post.new(context[:value])] }
    end

    result = schema.execute('{ posts { id } }', context: { value: 'context' })

    expect(result).to eq(
      'data' => {
        'posts' => [Post.new('context').to_json]
      }
    )
  end

  it 'can define complexity' do
    schema = define_search_class_and_return_schema do
      complexity 10_000
    end

    result = schema.execute '{ posts { id } }'

    expect(result).to eq(
      'errors' => [{
        'message' => 'Query has complexity of 10001, which exceeds max complexity of 1000'
      }]
    )
  end

  describe 'option' do
    it 'converts GraphQL::Schema::Enum to SearchObject enum' do
      schema = define_search_class_and_return_schema do
        enum_type = Class.new(GraphQL::Schema::Enum) do
          graphql_name 'PostOrder'

          value 'PRICE'
          value 'DATE'
        end

        option(:order, type: enum_type)

        define_method(:apply_order_with_price) do |_scope|
          [Post.new('price')]
        end

        define_method(:apply_order_with_date) do |_scope|
          [Post.new('date')]
        end
      end

      result = schema.execute '{ posts(order: PRICE) { id } }'

      expect(result).to eq(
        'data' => {
          'posts' => [Post.new('price').to_json]
        }
      )
    end

    it 'converts GraphQL::EnumType to SearchObject enum' do
      schema = define_search_class_and_return_schema do
        enum_type = Class.new(GraphQL::Schema::Enum) do
          graphql_name 'TestEnum'

          value 'PRICE'
          value 'DATE'
        end

        option(:order, type: enum_type)

        define_method(:apply_order_with_price) do |_scope|
          [Post.new('price')]
        end

        define_method(:apply_order_with_date) do |_scope|
          [Post.new('date')]
        end
      end

      result = schema.execute '{ posts(order: PRICE) { id } }'

      expect(result).to eq(
        'data' => {
          'posts' => [Post.new('price').to_json]
        }
      )
    end

    it 'accepts default type' do
      schema = define_search_class_and_return_schema do
        option(:id, type: String, default: 'default') do |_scope, value|
          [Post.new(value)]
        end
      end

      result = schema.execute '{ posts { id } }'

      expect(result).to eq(
        'data' => {
          'posts' => [Post.new('default').to_json]
        }
      )
    end

    it 'sets default_value on the argument' do
      schema = define_search_class_and_return_schema do
        type PostType, null: true

        option('option', type: String, default: 'default') { [] }
      end

      result = schema.execute <<~GRAPHQL
        {
          __type(name: "Query") {
            name
            fields {
              args {
                name
                defaultValue
              }
            }
          }
        }
      GRAPHQL

      expect(result).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => [{
                'name' => 'option',
                'defaultValue' => '"default"'
              }]
            }]
          }
        }
      )
    end

    it 'accepts "required"' do
      schema = define_search_class_and_return_schema do
        option(:id, type: String, required: true) do |_scope, value|
          [Post.new(value)]
        end
      end

      result = schema.execute '{ posts { id } }'

      expect(result['errors'][0]['message']).to eq("Field 'posts' is missing required arguments: id")
    end

    it 'accepts "argument_options"' do
      argument_options = {
        permission: true
      }
      schema = define_search_class_and_return_schema do
        option(:id, type: String, argument_options: argument_options) do |_scope, value|
          [Post.new(value)]
        end
      end

      result = schema.execute '{ posts(id: "2") { id } }'

      expect(result).to eq(
        'data' => {
          'posts' => [Post.new('2').to_json]
        }
      )
    end

    it 'accepts description' do
      schema = define_search_class_and_return_schema do
        type PostType, null: true

        option('option', type: String, description: 'what this argument does') { [] }
      end

      result = schema.execute <<-SQL
        {
          __type(name: "Query") {
            name
            fields {
              args {
                name
                description
              }
            }
          }
        }
      SQL

      expect(result).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => [{
                'name' => 'option',
                'description' => 'what this argument does'
              }]
            }]
          }
        }
      )
    end

    it 'accepts camelize' do
      schema = define_search_class_and_return_schema do
        type PostType, null: true

        option('option_field', type: String, camelize: false)
      end

      result = schema.execute <<-SQL
        {
          __type(name: "Query") {
            name
            fields {
              args {
                name
              }
            }
          }
        }
      SQL

      expect(result.to_h).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => [{
                'name' => 'option_field'
              }]
            }]
          }
        }
      )
    end

    it 'does not override the default camelize option' do
      schema = define_search_class_and_return_schema do
        type PostType, null: true

        option('option_field', type: String)
      end

      result = schema.execute <<~GRAPHQL
        {
          __type(name: "Query") {
            name
            fields {
              args {
                name
              }
            }
          }
        }
      GRAPHQL

      expect(result.to_h).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => [{
                'name' => 'optionField'
              }]
            }]
          }
        }
      )
    end

    it 'accepts deprecation_reason' do
      schema = define_search_class_and_return_schema do
        type PostType, null: true

        option('option', type: String, deprecation_reason: 'Not in use anymore')
      end

      result = schema.execute <<-SQL
        {
          __type(name: "Query") {
            name
            fields {
              args(includeDeprecated: false) {
                name
              }
            }
          }
        }
      SQL

      expect(result.to_h).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => []
            }]
          }
        }
      )

      result = schema.execute <<-SQL
        {
          __type(name: "Query") {
            name
            fields {
              args(includeDeprecated: true) {
                name
              }
            }
          }
        }
      SQL

      expect(result.to_h).to eq(
        'data' => {
          '__type' => {
            'name' => 'Query',
            'fields' => [{
              'args' => [{
                'name' => 'option',
              }]
            }]
          }
        }
      )
    end

    it 'raises error when no type is given' do
      expect { define_search_class { option :name } }.to raise_error described_class::MissingTypeDefinitionError
    end
  end
end
