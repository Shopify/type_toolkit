# The `def self.` problem

Ruby method definitions evaluate to the name of the method that was defined. This fact is used by the `public`/`protected`/`private` methods:

```ruby
class
  puts def demo; end
  # Equivalent to `puts(:demo)`
end
```

However, there's no way to distguish whether the method was an instance method, or a singleton method:

```ruby
class C
  puts def      demo; end # prints ":demo"
  puts def self.demo; end # *also* prints ":demo"
end
```

# Solution

Track into whether the last method call was an instance method or a singleton method, by hooking into `method_added` and `singleton_method_added`. See the `MethodDefRecorder` for details.

This way, both of these "just work"

```rb
class C
  # Correctly defines an abstract instance method
  abstract def      demo; end

  # Correctly defines an abstract "class method"
  abstract def self.demo; end
end
```

# Alternative 1: Do nothing

This is already a problem for access level modifiers, which don't do anything to handle it:

```ruby
class C
  private def self.demo; end
  # => ❌ undefined method 'demo' for class 'C' (NameError)
end
```

We can just follow suit. However, there's a risk that if an instance method called `demo` _actually_ existed, we inadvertently make it abstract without intenting. Again, the access level modifier methods already have this issue, but it's a sharp edge that we don't need to have.

If we choose to do nothing, we could encourage users to enable the [`Style/ClassMethodsDefinitions`](https://docs.rubocop.org/rubocop/cops_style.html#styleclassmethodsdefinitions) on the `EnforcedStyle: self_class` mode, so that their code bases don't contain `def self.foo` methods at all.

Pros:
  - Simpler implementation (none!)

Cons:
  - Sharp edge
  - More complex mental model for users of RBS

# Alternative 2: separate macro

E.g.

```rb
class C
  # Correctly defines an abstract instance method
  abstract_instance_method def demo; end

  # Correctly defines an abstract "class method"
  abstract_class_method def self.demo; end
end
```

Pros:
  - Simple implementation

Cons:
  - Correct usage can't be enforced at runtime.
    - Rubocop cop could enforce it, but that would need to be written
  - Still a sharp edge, has the same congnitive complexity as alternative 1.
