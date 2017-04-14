require 'spec_helper'
require 'graphql'
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

  it 'has ctx attribute' do
    search = define_search_class.new(ctx: :ctx)

    expect(search.ctx).to eq :ctx
  end

  it 'has obj attribute' do
    search = define_search_class.new(obj: :obj)

    expect(search.obj).to eq :obj
  end

  it 'can be used as resolver' do
    search_object = define_search_class do
      scope { [Post.new('1'), Post.new('2'), Post.new('3')] }

      option(:id) { |scope, value| scope.select { |p| p.id == value } }
    end

    result = execute_query_on_schema('{ posts(id: "2") { id } }') do
      field :posts do
        type types[PostType]
        argument :id, !types.ID
        resolve search_object
      end
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

      option(:argument) { |_scope, value| [obj, Post.new(ctx[:value]), Post.new(value)] }
    end

    parent_type = GraphQL::ObjectType.define do
      name 'ParentType'

      field :posts do
        type types[PostType]
        argument :argument, !types.String
        resolve search_object
      end
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

  it 'can use obj for getting a scope'

  describe 'dsl' do
    it 'works with connection type'
    it 'works with array type'
  end
end
