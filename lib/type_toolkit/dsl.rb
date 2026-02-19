# typed: strict
# frozen_string_literal: true

module TypeToolkit
  # @requires_ancestor: MethodDefRecorder
  module DSL
    # Mark `method_name` as abstract.
    #
    # A real implementation of the method must be provided somewhere in the ancestor chain.
    # Calls to an unimplemented abstract method will raise `AbstractMethodNotImplementedError`.
    #
    #: (Symbol) -> Symbol
    def abstract(method_name)
      #: self as (Module[top] & HasAbstractMethods & MethodDefRecorder)

      recorded_method_name, is_singleton_method = __last_method_def

      if recorded_method_name != method_name
        prefix = is_singleton_method ? "." : "#"

        # Do not rely on this message content! Its content is subject to change.
        raise <<~MSG.chomp
          `abstract` expected to see `#{prefix}#{method_name}`, but the last recorded method was called `#{recorded_method_name}`.
          This can happen when `abstract` is combined with other metaprogramming.
          If you think this is a bug, please open an issue: https://github.com/Shopify/type_toolkit/issues
        MSG
      end

      # The `method_owner` is the class whose method table stores the abstract method.
      #
      # Example:
      #
      #   class Foo
      #     # is_singleton_method = false, owner is the `Foo` class
      #     abstract def foo; end
      #
      #     # is_singleton_method = true, owner is `Foo.singleton_class`
      #     abstract def self.foo; end
      #   end
      method_owner = is_singleton_method ? singleton_class : self #: as Module[top] & HasAbstractMethods

      # Register the fact that this method is meant to be abstract,
      # used by APIs like `abstract_method_declared?` and `Method#abstract?`
      method_owner.__register_abstract_method(method_name)

      # We never want the empty "stub" method to be called, so we remove it. This has one of 3 effects:
      #
      # 1. If the abstract method is implemented by a subclass, then there's no effect.
      #    The subclass' implementation will always be invoked, so this removal does nothing.
      #
      # 2. If the abstract method was already implemented by a superclass,
      #    Then this removal ensures that calls to the method will resolve to
      #    the superclass' implementation, and never the empty stub.
      #
      # 3. If the abstract method was not implemented anywhere in the ancestor chain,
      #    then this removal ensures we hit `method_missing`, which will then raise
      #    the `AbstractMethodNotImplementedError`.
      method_owner.remove_method(method_name)

      # Return the method name, so `abstract` can be chained, e.g. `private abstract def foo; end`
      method_name
    end
  end
end
