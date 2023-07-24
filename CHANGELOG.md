# Changelog

## Version 1.0.4

* __[feature]__ Added `deprecation_reason` to `option` ([@IgrekYY](https://github.com/IgrekYY))

## Version 1.0.3

* __[fix]__ Support GraphQL 2.0 gem ([@rstankov](https://github.com/rstankov))

## Version 1.0.2

* __[feature]__ Added `argument_options` to `option` ([@wuz](https://github.com/wuz))

## Version 1.0.1

* __[fix]__ `camelize` defaults to false when not specified ([@haines](https://github.com/haines))

## Version 1.0.0

* __[break]__ Removed support for defining types via `type` method ([@rstankov](https://github.com/rstankov))
* __[break]__ Require `GraphQL::Schema::Resolver` inheritance ([@rstankov](https://github.com/rstankov))
* __[break]__ Removed support for legacy `GraphQL::Function` ([@rstankov](https://github.com/rstankov))
* __[break]__ `type` creates type based on `GraphQL::Schema::Object`, not the deprecated `GraphQL::ObjectType.define` ([@rstankov](https://github.com/rstankov))

## Version 0.3.2

* __[feature]__ Added `camelize` argument to `option`, *`true` by default* ([@glenbray](https://github.com/glenbray))

## Version 0.3.1

* __[fix]__ Support for GraphQL gem version v1.9.16 ([@ardinusawan](https://github.com/ardinusawan))

## Version 0.3

* __[feature]__ Allow passing `required` key to option definition ([@vfonic](https://github.com/vfonic))
* __[fix]__ Support for GraphQL gem enums ([@Postmodum37](https://github.com/Postmodum37))

## Version 0.2

* Added support for GraphQL::Schema::Resolver ([@rstankov](https://github.com/rstankov))
* Added support for GraphQL 1.8 class API ([@rstankov](https://github.com/rstankov))

## Version 0.1

* Initial release ([@rstankov](https://github.com/rstankov))
