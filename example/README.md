# SearchObject::Plugin::Graphql Example Rails Application

This is example application showing, one of the possible usages of ```SearchObject::Plugin::Graphql```.

## Interesting Files:

* [Types::QueryType](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/types/query_type.rb)
* [Types::CategoryType](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/types/category_type.rb)
* [Types::PostType](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/types/post_type.rb)
* [Resolvers::BaseSearchResolver](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/resolvers/base_search_resolver.rb)
* [Resolvers::CategoryResolver](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/resolvers/category_search.rb)
* [Resolvers::PostResolver](https://github.com/RStankov/SearchObjectGraphQL/blob/master/example/app/graphql/resolvers/post_search.rb)

## Installation

```
gem install bundler
bundle install
rails db:create
rails db:migrate
rails db:seed

rails server
```

From there just visit: [localhost:3000/](http://localhost:3000/). This would open [graphiql](https://github.com/graphql/graphiql).

## Sample GraphQL Queries

```
{
  categories {
    edges {
      node {
        id
        name
        posts(published: false) {
          edges {
            node {
              id
              title
            }
          }
        }
      }
    }
  }
}
```

```graphql
{
  posts(first: 10, published: true, order: VIEWS) {
    edges {
      node {
        title
        isPublished
        viewsCount
        publishedAt
      }
    }
  }
}
```

```graphql
{
  posts(first: 10, title: "Example", order: VIEWS) {
    edges {
      node {
        title
        category {
          id
          name
        }
        isPublished
        viewsCount
        publishedAt
      }
    }
  }
}
```
