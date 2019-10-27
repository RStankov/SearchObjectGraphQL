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
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Query'

      instance_eval(&block)
    end

    Class.new(GraphQL::Schema) do
      query query_type

      max_complexity 1000
    end
  end

  def define_search_class(&block)
    Class.new do
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

  it 'can be used as GraphQL::Schema::Resolver' do
    post_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Post'

      field :id, GraphQL::Types::ID, null: false
    end

    search_object = define_search_class do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      type [post_type]

      option(:id, type: !types.ID) { |scope, value| scope.select { |p| p.id == value } }
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

  it 'can be used as GraphQL::Function' do
    post_type = GraphQL::ObjectType.define do
      name 'Post'

      field :id, !types.ID
    end

    search_object = define_search_class do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      type types[post_type]

      option(:id, type: !types.ID) { |scope, value| scope.select { |p| p.id == value } }
    end

    schema = define_schema do
      field :posts, function: search_object
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

  it 'can define a custom type' do
    schema = define_search_class_and_return_schema do
      type do
        name 'Test'

        field :title, types.String
      end

      description 'Test description'
    end

    result = schema.execute <<-SQL
      {
        __type(name: "Query") {
          name
          fields {
            name
            deprecationReason
            type {
              name
              fields {
                name
              }
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
            'name' => 'posts',
            'deprecationReason' => nil,
            'type' => {
              'name' => 'Test',
              'fields' => [{
                'name' => 'title'
              }]
            }
          }]
        }
      }
    )
  end

  it 'can be marked as deprecated' do
    schema = define_search_class_and_return_schema do
      type [PostType]
      deprecation_reason 'Not needed any more'
    end

    result = schema.execute <<-QUERY
      {
        __type(name: "Query") {
          name
          fields {
            name
          }
        }
      }
    QUERY

    expect(result.to_h).to eq(
      'data' => {
        '__type' => {
          'name' => 'Query',
          'fields' => []
        }
      }
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
        enum_type = GraphQL::EnumType.define do
          name 'TestEnum'

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
        option(:id, type: types.String, default: 'default') do |_scope, value|
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

    it 'accepts "required"' do
      schema = define_search_class_and_return_schema do
        option(:id, type: types.String, required: true) do |_scope, value|
          [Post.new(value)]
        end
      end

      result = schema.execute '{ posts { id } }'

      expect(result['errors'][0]['message']).to eq("Field 'posts' is missing required arguments: id")
    end

    it 'accepts description' do
      schema = define_search_class_and_return_schema do
        type PostType

        option('option', type: types.String, description: 'what this argument does') { [] }
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

    it 'raises error when no type is given' do
      expect { define_search_class { option :name } }.to raise_error described_class::MissingTypeDefinitionError
    end
  end
end
