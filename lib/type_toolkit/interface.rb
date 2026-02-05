# frozen_string_literal: true

module TypeToolkit
  # This module is extended onto any module that represents an interface.
  # All of its members should be public and abstract.
  module Interface
    # TODO: interfaces should not have private or protected members. Hook into method_added to enforce this.

    # TODO: enforce that the attached-object isn't a module. https://sorbet.org/docs/abstract#abstract-singleton-methods
    # > abstract singleton methods on a module are not allowed, as there’s no way to implement these methods.

    def included(target_module)
      # Including/extending a module is idempotent, so we don't have to worry these were already included/extended.

      # Potentially abstract methods will be called on instances of `self`, so we need the `method_missing` hooks.
      target_module.include(TypeToolkit::AbstractInstanceMethodReceiver)

      # The `method_missing` hooks need to be able to look up the abstract methods (from the interface).
      target_module.extend(TypeToolkit::HasAbstractMethods)
    end
  end
end
