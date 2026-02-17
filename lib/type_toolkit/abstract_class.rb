# frozen_string_literal: true

# Raised when an attempt is made to instantiate an abstract class.
CannotInstantiateAbstractClassError = Class.new(Exception) # rubocop:disable Lint/InheritException

module TypeToolkit
  module AbstractClass
    def new(...) # :nodoc:
      raise CannotInstantiateAbstractClassError, "#{self.class.name} is declared as abstract; it cannot be instantiated"
    end

    def inherited(subclass)
      if subclass.singleton_class.superclass.include?(TypeToolkit::AbstractClass) &&
          !subclass.singleton_class.superclass.singleton_class.include?(TypeToolkit::AbstractClass)

        # We only ned to restore the original `.new` implementation for the direct subclasses of the abstract class.
        # That's then inherited by the indirect subclasses.
        # TODO: test this behaviour.
        subclass.singleton_class.alias_method(:new, :__original_new_impl)

        # We don't need a reference to the original implementation anymore,
        # so let's undef it to limit namespace pollution.
        subclass.singleton_class.undef_method(:__original_new_impl)
      end

      super
    end
  end
end
