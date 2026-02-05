# typed: true
# frozen_string_literal: true

module TypeToolkit
  class << self
    #: (Module[top]) -> void
    def make_abstract!(mod)
      case mod
      when Class
        # We need to save the original implementation of `new`, so we can restore it on the subclasses later.
        mod.singleton_class.alias_method(:__original_new_impl, :new)

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

      if respond_to?(:__original_new_impl) # This is true for the abstract classes themselves, and false for their subclasses.
        raise CannotInstantiateAbstractClassError, "#{self.class.name} is declared as abstract; it cannot be instantiated"
      end

      # This is hit in the uncommon case where a subclass of an abstract class overrides `.new` and calls `super`.
      super
    end

    # Restores the original `.new` implementation for the direct subclasses of an abstract class.
    #: (Class[AbstractClass]) -> void
    def inherited(subclass) # :nodoc:
      superclass = subclass.singleton_class.superclass #: as !nil

      if superclass.include?(TypeToolkit::AbstractClass) &&
          !superclass.singleton_class.include?(TypeToolkit::AbstractClass)
        # We only need to restore the original `.new` implementation for the direct subclasses of the abstract class.
        # That's then inherited by the indirect subclasses.

        subclass.singleton_class.alias_method(:new, :__original_new_impl)

        # We don't need a reference to the original implementation anymore,
        # so let's undef it to limit namespace pollution.
        subclass.singleton_class.undef_method(:__original_new_impl)
      end

      super
    end
  end

  # Raised when an attempt is made to instantiate an abstract class.
  class CannotInstantiateAbstractClassError < Exception # rubocop:disable Lint/InheritException
  end
end
