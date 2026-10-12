# typed: true
# frozen_string_literal: true

require "type_toolkit/dsl"
require "type_toolkit/method_def_recorder"
require "type_toolkit/has_abstract_methods"
require "type_toolkit/abstract_method_receiver"

module TypeToolkit
  class << self
    #: (Module[top]) -> void
    def make_abstract!(mod)
      case mod
      when Class
        if mod.singleton_class.method_defined?(:__type_toolkit_private_original_new_impl, false)
          raise AlreadyDeclaredAbstractError, "#{mod.inspect} is already declared abstract"
        end

        if mod.singleton_class?
          raise NotImplementedError, "Declaring `abstract!` from a singleton class is not supported yet."
        end

        if TypeToolkit::AbstractClass > mod.singleton_class # Check if AbstractClass was already extended up in mod's ancestor chain.
          raise NotImplementedError, "Declaring a subclass of an abstract class as abstract is not supported yet."
        end

        # We need to save the original implementation of `new`, so we can restore it on the subclasses later.
        mod.singleton_class.alias_method(:__type_toolkit_private_original_new_impl, :new)

        mod.extend(TypeToolkit::AbstractClass)
        mod.extend(TypeToolkit::DSL)
        mod.extend(TypeToolkit::MethodDefRecorder)
        mod.extend(TypeToolkit::HasAbstractMethods)

        mod.include(TypeToolkit::AbstractInstanceMethodReceiver)
      when Module
        raise NotImplementedError, "Abstract modules are not implemented yet."
      end
    end
  end

  # This module is extended onto every class marked `abstract!`.
  # Abstract classes can't be instantiated, only subclassed.
  # They should contain abstract methods, which must be implemented by subclasses.
  #
  # Example:
  #
  #   class Widget
  #     abstract!
  #
  #     #: -> void
  #     abstract def draw; end
  #   end
  #
  #   class Button < Widget
  #     # @override
  #     #: -> void
  #     def draw
  #       ...
  #     end
  #   end
  #
  #   class TextField < Widget
  #     # @override
  #     #: -> void
  #     def draw
  #       ...
  #     end
  #   end
  #
  module AbstractClass
    # An override of `new` which prevents instantiation of the class.
    # This needs to be overridden again in subclasses, to restore the real `.new` implementation.
    def new(...) # :nodoc:
      #: self as Class[top]

      if respond_to?(:__type_toolkit_private_original_new_impl) # This is true for the abstract classes themselves, and false for their subclasses.
        raise CannotInstantiateAbstractClassError, "#{inspect} is declared as abstract; it cannot be instantiated"
      end

      # This is hit in the uncommon case where a subclass of an abstract class overrides `.new` and calls `super`.
      super
    end

    # Restores the original `.new` implementation for the direct subclasses of an abstract class.
    #: (Class[AbstractClass]) -> void
    def inherited(subclass) # :nodoc:
      if subclass.singleton_class.method_defined?(:__type_toolkit_private_original_new_impl)
        # We only need to restore the original `.new` implementation for the direct subclasses of the abstract class.
        # That's then inherited by the indirect subclasses.

        if AbstractClass == subclass.singleton_class.instance_method(:new).owner
          # The raising `new` implementation is still in place, so we need to restore the original implementation we stashed away.
          subclass.singleton_class.alias_method(:new, :__type_toolkit_private_original_new_impl)
        else
          # The parent class defined its own `new` after being declared `abstract!`.
          # We just inherit that implementation without needing to do anything.
        end

        # We don't need a reference to the original implementation anymore,
        # so let's undef it to limit namespace pollution.
        subclass.singleton_class.undef_method(:__type_toolkit_private_original_new_impl)
      end

      super
    end
  end

  # Raised when an attempt is made to instantiate an abstract class.
  class CannotInstantiateAbstractClassError < Exception # rubocop:disable Lint/InheritException
  end

  # Raised when you attempt to call `abstract!` twice on the exact same class.
  class AlreadyDeclaredAbstractError < Exception # rubocop:disable Lint/InheritException
  end
end
