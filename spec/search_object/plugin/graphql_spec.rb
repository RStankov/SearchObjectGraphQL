# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'ostruct'
require 'search_object/plugin/graphql'

describe SearchObject::Plugin::Graphql do
  Post = Struct.new(:id) do
    def to_json
      { 'id' => id }
    end
  end

  PostType = GraphQL::ObjectType.define do
    name 'Post'

    field :id, !types.ID
  end

  def define_schema(&block)
    query_type = GraphQL::ObjectType.define do
      name 'Query'

      instance_eval(&block)
    end

    GraphQL::Schema.define do
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
        field :posts, types[PostType], function: search_object
      else
        field :posts, function: search_object
      end
    end
  end

  it 'can be used as GraphQL::Function' do
    schema = define_search_class_and_return_schema do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      option(:id, type: !types.ID) { |scope, value| scope.select { |p| p.id == value } }
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

    parent_type = GraphQL::ObjectType.define do
      name 'ParentType'

      field :posts, types[PostType], function: search_object
    end

    schema = define_schema do
      field :parent, parent_type do
        resolve ->(_obj, _args, _ctx) { OpenStruct.new posts: [Post.new('from_parent')] }
      end
    end

    result = schema.execute '{ parent { posts { id }  } }'

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
      type types[PostType]
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

    expect(result).to eq(
      'data' => {
        '__type' => {
          'name' => 'Query',
          'fields' => []
        }
      }
    )
  end

  describe 'option' do
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
