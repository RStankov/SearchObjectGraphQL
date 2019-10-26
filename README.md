[![Gem Version](https://badge.fury.io/rb/search_object_graphql.svg)](http://badge.fury.io/rb/search_object_graphql)
[![Code Climate](https://codeclimate.com/github/RStankov/SearchObjectGraphQL.svg)](https://codeclimate.com/github/RStankov/SearchObjectGraphQL)
[![Build Status](https://secure.travis-ci.org/RStankov/SearchObjectGraphQL.svg)](http://travis-ci.org/RStankov/SearchObjectGraphQL)
[![Code coverage](https://coveralls.io/repos/RStankov/SearchObjectGraphQL/badge.svg?branch=master#2)](https://coveralls.io/r/RStankov/SearchObjectGraphQL)

# SearchObject::Plugin::GraphQL

[SearchObject](https://github.com/RStankov/SearchObject) plugin for [GraphQL Ruby](https://rmosolgo.github.io/graphql-ruby/).

## Table of Contents

* [Installation](#installation)
* [Dependencies](#dependencies)
* [Usage](#usage)
  * [Example](#example)
* [Features](#features)
  * [Custom Types](#custom-types)
  * [Documentation](#documentation)
  * [Default Values](#default-values)
  * [Accessing Parent Object](#accessing-parent-object)
  * [Enums Support](#enums-support)
  * [Relay Support](#relay-support)
* [Contributing](#contributing)
* [License](#license)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'search_object_graphql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install search_object_graphql


**Require manually in your project**

```ruby
require 'search_object'
require 'search_object/plugin/graphql'
```

## Dependencies

- `SearchObject` >= 1.2
- `Graphql` >= 1.5

## Usage

Just include the ```SearchObject.module``` and define your search options and their types:

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  type [PostType], null: false

  scope { Post.all }

  option(:name, type: String)       { |scope, value| scope.where name: value }
  option(:published, type: Boolean) { |scope, value| value ? scope.published : scope.unpublished }
end
```

Then you can just use `PostResolver` as [GraphQL::Schema::Resolver](https://graphql-ruby.org/fields/resolvers.html):

```ruby
field :posts, resolver: PostResolver
```

Options are exposed as arguments in the GraphQL query:

```
posts(name: 'Example') { ... }
posts(published: true) { ... }
posts(published: true, name: 'Example') { ... }
```

### Example

You can find example of most important features and plugins - [here](https://github.com/RStankov/SearchObjectGraphQL/tree/master/example).

## Features

### Documentation

Search object itself can be documented, as well as its options:

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  description 'Lists all posts'

  option(:name, type: types.String, description: 'Fuzzy name matching') { ... }
  option(:published, type: types.Boolean, description: 'Find published/unpublished') { ... }
end
```

### Default Values

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  scope { Post.all }

  option(:published, type: types.Boolean, default: true) { |scope, value| value ? scope.published : scope.unpublished }
end
```

### Accessing Parent Object

Sometimes you want to scope posts based on parent object, it is accessible as `object` property:

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  # lists only posts from certain category
  scope { object.posts }

  # ...
end
```

If you need GraphQL context, it is accessible as `context`.

### Enums Support

```ruby
class PostSearch
  include SearchObject.module(:graphql)

  OrderEnum = GraphQL::EnumType.define do
    name 'PostOrder'

    value 'RECENT'
    value 'VIEWS'
    value 'COMMENTS'
  end

  option :order, type: OrderEnum, default: 'RECENT'

  def apply_order_with_recent(scope)
    scope.order 'created_at DESC'
  end

  def apply_order_with_views(scope)
    scope.order 'views_count DESC'
  end

  def apply_order_with_comments(scope)
    scope.order 'comments_count DESC'
  end
end
```

### Relay Support

Search objects can be used as [Relay Connections](https://graphql-ruby.org/relay/connections.html):

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  type PostType.connection_type, null: false

  # ...
end
```

```ruby
field :posts, resolver: PostResolver
```

### Legacy Function Support

```ruby
class PostResolver
  include SearchObject.module(:graphql)

  type [PostType], null: false

  # ...
end
```

```ruby
field :posts, function: PostResolver
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Run the tests (`rake`)
6. Create new Pull Request

## License

**[MIT License](https://github.com/RStankov/SearchObjectGraphQL/blob/master/LICENSE.txt)**
