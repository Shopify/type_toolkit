# typed: strict
# frozen_string_literal: true

require_relative "dsl"
require_relative "method_def_recorder"
require_relative "has_abstract_methods"
require_relative "abstract_method_receiver"

module TypeToolkit
  class << self
    #: (Module[top]) -> void
    def make_interface!(mod)
      if Class === mod
        raise TypeError, "Classes can't be interfaces. Did you mean to make it `abstract` instead?"
      end

      mod.extend(TypeToolkit::Interface)
      mod.extend(TypeToolkit::DSL)
      mod.extend(TypeToolkit::MethodDefRecorder)
      mod.extend(TypeToolkit::HasAbstractMethods)
    end
  end

  # This module is extended onto any module that represents an interface.
  # All of its members should be public and abstract.
  module Interface
    #: (Module[top]) -> void
    def included(target_module)
      install_onto(target_module)
    end

    #: (Module[top]) -> void
    def extended(target_module)
      install_onto(target_module.singleton_class)
    end

    private

    #: (Module[top]) -> void
    def install_onto(target_module)
      # Including/extending a module is idempotent, so we don't have to worry these were already included/extended.

      # Potentially abstract methods will be called on instances of `self`, so we need the `method_missing` hooks.
      if target_module.singleton_class?
        # Handle cases like:
        #
        #     class C
        #       class << self
        #         include TheInterface
        #       end
        #     end
        target_module.include(TypeToolkit::AbstractClassMethodReceiver)
      else
        # Handle the usual cases like:
        #
        #     class C
        #       include TheInterface
        #     end
        target_module.include(TypeToolkit::AbstractInstanceMethodReceiver)
      end

      # The `method_missing` hooks need to be able to look up the abstract methods (from the interface).
      target_module.extend(TypeToolkit::HasAbstractMethods)
    end
  end
end
