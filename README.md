# TypeToolkit

[💎 RubyGems](https://rubygems.org/gems/type_toolkit)

A minimal runtime library for implementing abstract classes, interfaces, and more.

## Installation

Install Type Toolkit into your bundle, add it to your `Gemfile`:

```rb
gem "type_toolkit"
```

And then run `bundle install`.

### RuboCop Cops

This gem ships with RuboCop cops that we recommend you enable for your application. You can do so by adding it to the `plugins` list of your `rubocop.yml`:

```yml
plugins:
  - rubocop-other-extension
  - type_toolkit:
      require_path: rubocop-type_toolkit
```

### Cherry-picking features

Simply writing `gem "type_toolkit"` in your `Gemfile` will grab all the tools from the toolkit, which we highly recommend. This adds methods to Ruby's core classes, to make them feel like a native part of the language.

Alternatively, you can cherry-pick only the tools you need. For example, if you only want to use the `not_nil!` assertion, you can add the following to your `Gemfile`:

```rb
gem "type_toolkit", require: ["type_toolkit/ext/nil_assertions"]
```

or you can skip the require in the `Gemfile`, and later manually require it in a specific file:

```ruby
gem "type_toolkit", require: false
```

```ruby
# your_script.rb
require "type_toolkit/ext/nil_assertions"
```


## Tools

### `not_nil!` assertion

When debugging a `nil`-related error, it can be difficult to trace back where the `nil` actually originated from. It could have come in from a parameter, whose argument was read from an instance variable, on an object loaded from a cache, populated by some totally different request.

If a value can't be nil, it's best for that to be clearly asserted as close to where that nilable value was first generated. That way, a rogue `nil` isn't allowed to propagate arbitrarily far away in downstream code.

Type Toolkit provides a `not_nil!` assertion, which will raise an `UnexpectedNilError` if the receiver is `nil`.

```rb
# `__dir__` can be nil in an "eval", but never in a Ruby file.
gemfile = Pathname.new(__dir__.not_nil!) / "Gemfile"
```

`not_nil!` method calls can be chained, to fail early if any value in the chain is `nil`:

```rb
last_delivery = user.not_nil!
  .orders.last.not_nil!
  .deliveries.last.not_nil!
```

## Guiding Principles

### Blazingly fast™

All tools should aim to have 0 overhead at runtime, as compared to hand-written Ruby.

### Pay only for what you use

There should be no performance cost for a tool that you're not using.

Wherever there's an unavoidable cost, it should only ever apply to code that actually uses the tool. **No global costs.**

Tools should be optimized for the common case, even if that slows them in rare cases. For example, calling an abstract method is as fast as calling any other method, but only if it's implemented. Calling an unimplemented method call hits the `#method_missing` path, which is significantly slower. This is an acceptable trade-off, because no production code should be calling `#method_missing`, anyway.

In all cases, performance costs are quantified and well-documented.

### Feels like Ruby

Tools should feel like part of a programming language itself, and less like its standard library. Type Toolkit takes on the implementation complexity so your code doesn't have to.

To keep that bar high, the toolkit is lean and deliberately focused on
language-level primitives. Where practical, new
features should be built in separate libraries that _use_ the Type Toolkit.

## Development

This repo has Rake tasks configured for common development tasks:
1. `bundle exec rake` to do the next 3 steps all together
1. `bundle exec rake rubocop` for linting
1. `bundle exec rake typecheck` to typecheck with Sorbet
1. `bundle exec rake test` to run all the tests
1. `bundle exec rake -T` to list all the tasks

### Releasing

This gem is automatically released to [RubyGems.org](https://rubygems.org/gems/type_toolkit) via [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/). To publish a new version of the gem, all you have to do is:

1. Update the version number in [`version.rb`](https://github.com/Shopify/type_toolkit/blob/main/lib/type_toolkit/version.rb)
    * This can either be part of an existing PR, or a new standalone PR.

2. Once that PR is merged, create a tag at the new head of the `main` branch:

    ```sh
    git pull origin main && git checkout main && git tag v1.2.3
    ```

3. Push the new tag.

    ```sh
    git push origin v1.2.3
    ```

    This will automatically trigger our [release workflow](https://github.com/Shopify/type_toolkit/actions/workflows/release.yml). It must be approved by a member of the Ruby and Rails Infrastructure team at Shopify before it will run.

Once approved, the workflow will automatically publish the new gem version to RubyGems.org, and create a new [GitHub release](https://github.com/Shopify/type_toolkit/releases).
