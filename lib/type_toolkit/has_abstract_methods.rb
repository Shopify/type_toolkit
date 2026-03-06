# typed: strict
# frozen_string_literal: true

module TypeToolkit
  # Given a class Foo, abstract methods can be defined at two levels:
  # 1. Instance methods available on the instance of Foo
  # 2. "Class methods" available on the Foo class itself
  #
  # In case 1, the storage belongs one level up, in the class Foo.
  # In case 2, the storage belongs two levels up, in the singleton class of Foo (`Foo::<Foo>`)
  module HasAbstractMethods
    # Private API, do not use directly. Only meant to be called from the `abstract` macro.
    #: (Symbol) -> void
    def __register_abstract_method(method_name) # :nodoc:
      (
        @__abstract_methods ||= Set.new #: Set[Symbol]?
      ) << method_name
    end

    # Returns all methods that were marked abstract (even those which are implemented).
    #: (?bool) -> Array[Symbol]
    def declared_abstract_instance_methods(include_super = true)
      #: self as HasAbstractMethods & Module[top]

      result = @__abstract_methods #: Set[Symbol]?

      if include_super
        ancestors.each do |m|
          methods = m.instance_variable_get(:@__abstract_methods)
          if methods&.any?
            if result
              result.merge(methods)
            else
              result = methods
            end
          end
        end
      end

      result.to_a
    end

    # Returns all methods that are abstract and have not been implemented.
    #: (?bool) -> Array[Symbol]
    def abstract_instance_methods(include_super = true)
      #: self as HasAbstractMethods & Module[top]

      declared_abstract_instance_methods(include_super).reject do |m|
        method_defined?(m) || private_method_defined?(m)
      end
    end

    # Returns true if the given method name was ever marked abstract, even if it has a concrete implementation.
    #
    # Similar to `public_method_defined?` and friends, this method is called on a class to check if the method
    # is defined for _instances_ of that class. For example:
    #
    #     if Foo.abstract_method_declared?(:instance_method)
    #       Foo.new.instance_method # Might raise AbstractMethodNotImplementedError
    #     end
    #
    #     if Foo.singleton_class.abstract_method_declared?(:class_method)
    #       Foo.class_method # Might raise AbstractMethodNotImplementedError
    #     end
    #
    #: (Symbol) -> bool
    def abstract_method_declared?(method_name)
      #: self as Module[top]

      # FIXME: Allocating the `ancestors` array is not great.
      # I tried a recursive approach, but that didn't quite work.
      # There is only one implementation of `abstract_method_declared?` in the ancestor chain, so there is no `super` to call.
      # This method always checked the ivar of the current class, which might not be set. What we actually want is to
      # walk up the ancestor chain, and check the ivar of each ancestor.
      ancestors.any? do |m|
        m.instance_variable_get(:@__abstract_methods)&.include?(method_name)
      end
    end

    # Returns true if the given method is abstract, and has not been implemented.
    # Calling it *will* raise an `AbstractMethodNotImplementedError`.
    #
    # Similar to `public_method_defined?` and friends, this method is called on a class to check if the method
    # is defined for _instances_ of that class. For example:
    #
    #     if Foo.abstract_method?(:instance_method)
    #       Foo.new.instance_method # Will raise AbstractMethodNotImplementedError
    #     end
    #
    #     if Foo.singleton_class.abstract_method?(:class_method)
    #       Foo.class_method # Will raise AbstractMethodNotImplementedError
    #     end
    #
    #: (Symbol) -> bool
    def abstract_method?(method_name)
      #: self as (HasAbstractMethods & Module[top])

      # If the method is defined, it has a concrete implementation, so it's not abstract.
      return false if method_defined?(method_name) || private_method_defined?(method_name)

      abstract_method_declared?(method_name)
    end
  end
end
