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

  def execute_query_on_schema(query_string, context: {}, &block)
    query_type = GraphQL::ObjectType.define do
      name 'Query'

      instance_eval(&block)
    end

    schema = GraphQL::Schema.define do
      query query_type
    end

    schema.execute(query_string, context: context)
  end

  def define_search_class(&block)
    Class.new do
      include SearchObject.module(:graphql)

      if block_given?
        instance_eval(&block)
      else
        scope { [] }
      end
    end
  end

  it 'has context attribute' do
    search = define_search_class.new(context: :context)

    expect(search.context).to eq :context
  end

  it 'has object attribute' do
    search = define_search_class.new(object: :object)

    expect(search.object).to eq :object
  end

  it 'can be used as function' do
    search_object = define_search_class do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      type types[PostType]

      option(:id, type: !types.ID) { |scope, value| scope.select { |p| p.id == value } }
    end

    result = execute_query_on_schema('{ posts(id: "2") { id } }') do
      field :posts, function: search_object
    end

    expect(result).to eq(
      'data' => {
        'posts' => [Post.new('2').to_json]
      }
    )
  end

  it 'all data is passed' do
    search_object = define_search_class do
      scope { [] }

      option(:argument, type: !types.String) { |_scope, value| [object, Post.new(context[:value]), Post.new(value)] }
    end

    parent_type = GraphQL::ObjectType.define do
      name 'ParentType'

      field :posts, types[PostType], function: search_object
    end

    result = execute_query_on_schema('{ parent { posts(argument: "argument") { id }  } }', context: { value: 'context' }) do
      field :parent do
        type parent_type
        resolve ->(_obj, _args, _ctx) { Post.new('parent') }
      end
    end

    expect(result).to eq(
      'data' => {
        'parent' => {
          'posts' => [Post.new('parent').to_json, Post.new('context').to_json, Post.new('argument').to_json]
        }
      }
    )
  end

  it 'can use object for getting a scope' do
    search_object = define_search_class do
      scope { object.posts }

      type types[PostType]
    end

    parent_type = GraphQL::ObjectType.define do
      name 'ParentType'

      field :posts, function: search_object
    end

    result = execute_query_on_schema('{ parent { posts { id }  } }') do
      field :parent do
        type parent_type
        resolve ->(_obj, _args, _ctx) { OpenStruct.new posts: [Post.new('id')] }
      end
    end

    expect(result).to eq(
      'data' => {
        'parent' => {
          'posts' => [Post.new('id').to_json]
        }
      }
    )
  end

  it 'auto generates enums'

  describe 'as GraphQL::Function'
end
