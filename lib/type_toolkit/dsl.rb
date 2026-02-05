# frozen_string_literal: true

module TypeToolkit
  module DSL
    # Mark `method_name` as abstract.
    #
    # A real implementation of the method must be provided somewhere in the ancestor chain.
    # Calls to an unimplemented abstract method will raise `AbstractMethodNotImplementedError`.
    #
    #: (method_name : Symbol) -> void
    def abstract(method_name)
      _recorded_method_name, is_singleton_method = __last_method_def

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
      method_owner = is_singleton_method ? singleton_class : self

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
    end
  end
end
