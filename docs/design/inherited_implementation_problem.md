# The inherited implementation problem

Take this example:

```ruby
class Parent
  def m = "Parent#m"
end
  
module I
  interface!

  abstract def m = raise "Abstract method `#m` not implemented"
end

class Child < Parent
  include I
end

Child.new.m 
# => Vanilla Ruby:   raises (from `I#m`)
# => With this gem: `Parent#m`
```

There are two challenges here:

  1. We need to not let the `I#m` stub implementation "get in the way", so that we can find real implementation that get inherited from further ancestors (like `Parent#m`).
  2. *but* we still want something to raise an error if you attempt to call an unimplemented abstract method.

If you lookup `m` on an instance of `Child`, you would usually hit the empty stub `I#m` instead of the inherited implementation `Parent#m`:

```ruby
Child.ancestors

# => [Child, Interface, Parent, Object, Kernel, BasicObject]
#     ^      ^          ^
#     |      |          Provides the implementation for Child to inherit
#     |      Its stub abstract method "gets in the way" and needs to be side-stepped
#     We want Child to inherit the implementation from Parent


Child.instance_method(:m).owner
# => Vanilla Ruby:  `I`
# => With this gem: `Parent`
```

# Solution

Solve the inheritance problem by just yoinking the abstract method stub out of the ancestor chain, by just using `remove_method()`.

Now if you send `#m` to a child, there's no `I#m` implementation to hit, so it just jumps over to `Parent#m`. This is a direct method call with absolutely no runtime overhead.

This introduces a new problem, that now calling unimplemented abstract methods just raises `NoMethodError`, as if the name never existed. For a better developer experience, we'd like to give a more helpful message.

To do this, we implement `#method_missing` and check if the missing method name is one of the abstract methods (based on a list we append to every time you call `abstract`). If it is, we can raise our nicer error, otherwise we just delegate up the rest of the `#method_missing` chain (ultimately triggering a `NoMethodError`, like normal). This part isn't strictly necessary, but it's a nice-to-have. We can make it configurable.

Syntax:

```ruby
module I
  interface!

  abstract def m; end
end
```

That's it. That simple!

Pros:
  - Good DX when calling an abstract method that you forgot to implement
  - Really nice syntax

Cons:
  - Some implementation complexity (but all tucked into this gem, with less than 130 lines of implementation code)
  - Calls to implemented abstract methods are faster, at the expense of unimplemented ones
    - 1.9x slower than the hand-written alternative
    - 1.1x slower than sorbet-runtime alternative
    - but that's totally acceptable, because this should never happen in a completed program. The performance of calls to actually implemented methods is what matters, since that's what the real code will be doing at a huge volume.

# Alternative 1: Hand-written delegation

You duplicate this delegation logic in every abstract method:

```ruby
module I
  interface!

  # @abstract
  def m = defined?(super) ? super : raise("Abstract method `#m` not implemented")
end
```

Pros:
  - There's no magic, no runtime needed.

Cons:
  - Repetitive
  - Can be forgotten
  - There's more overhead on every method call (but only to abstract methods with an inherited implementation):
    - Checking `defined?(super)`
    - Making the `super` call
  - It adds an extra frame to your backtrace which will be seen in debuggers and exception backtraces (unless you configure them to filter it out)


# Alternative 2: Sorbet runtime's solution

Here's a Sorbet version of the example: [Sorbet.run](https://sorbet.run/#%23%20typed%3A%20true%0A%0Aclass%20Parent%0A%20%20extend%20T%3A%3ASig%0A%0A%20%20sig%20%7B%20returns%28String%29%20%7D%0A%20%20def%20m%20%3D%20%22Parent%23m%22%0Aend%0A%20%20%0Amodule%20I%0A%20%20extend%20T%3A%3ASig%0A%20%20extend%20T%3A%3AHelpers%0A%0A%20%20interface!%0A%0A%20%20sig%20%7B%20abstract.returns%28String%29%20%7D%0A%20%20def%20m%3B%20end%0Aend%0A%0Aclass%20Child%20%3C%20Parent%3B%20end).

Sorbet runtime basically automates the hand-written solution above, by wrapping abstract methods:

https://github.com/sorbet/sorbet/blob/703498a0dcddbe7ec4b87ec6cc5d7d55cfa9b270/gems/sorbet-runtime/lib/types/private/methods/call_validation.rb#L48-L68

Pros:
  - "just works"

Cons:
  - All the downsides of doing this the hand-written way.
  - To determine if a method is abstract or not, every `sig` needs to have its block evaluated, to see if it calls `abstract`.
  - This used to be slower because it was defined via `defined_methods` with a block body. This produces a slower kind of method (`VM_METHOD_TYPE_BMETHOD`), than the equivalent code via `def` (`VM_METHOD_TYPE_ISEQ`). This was fixed in [this PR](https://github.com/sorbet/sorbet/pull/8238), which switch to using `module_eval` to define the method via `def`.
