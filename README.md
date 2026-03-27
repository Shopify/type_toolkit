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

### Interfaces

Interfaces are modules with abstract methods which a conforming class must implement. They help make duck-typing easier to use in Ruby, by validating that your conforming classes do actually provide the correct methods needed of them.

The Type Toolkit provides runtime support for interfaces (marked with `interface!`) and abstract methods (marked with `abstract` before the `def` keyword).

Example:

```ruby
module Notifier
  interface!

  #: (String) -> void
  abstract def send_notification(message); end
end

class SlackNotifier
  include Notifier

  # @override
  #: (String) -> void
  def send_notification(message)
    puts "Posting to Slack API: #{message.inspect}"
  end
end

SlackNotifier.new.send_notification("Hel
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).