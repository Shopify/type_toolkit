# frozen_string_literal: true

require_relative "type_toolkit/version"
require_relative "type_toolkit/dsl"
require_relative "type_toolkit/method_def_recorder"
require_relative "type_toolkit/interface"
require_relative "type_toolkit/abstract_class"

# Raised when a call is made to an abstract method that never had a real implementation.
AbstractMethodNotImplementedError = Class.new(Exception) # rubocop:disable Lint/InheritException

module TypeToolkit
  # Given a class Foo, abstract methods can be defined at two levels:
  # 1. Instance methods available on the instance of Foo
  # 2. "Class methods" available on the Foo class itself
  #
  # In case 1, the storage belongs one level up, in the class Foo.
  # In case 2, the storage belongs two levels up, in the singleton class of Foo (`Foo::<Foo>`)
  module HasAbstractMethods
    # Private API, do not use directly. Only meant to be called from the `abstract` macro.
    def __register_abstract_method(method_name) # :nodoc:
      (@__abstract_methods ||= Set.new) << method_name
    end

    # Returns all methods that were makred abstract (even those which are implemented).
    # TODO: change semantics to only return methods that are actually abstract and unimplemented.
    # : (include_super = true) -> Array[Symbol]
    def abstract_instance_methods(include_super = true)
      result = @__abstract_methods || Set.new

      ancestors.each do |m|
        methods = m.instance_variable_get(:@__abstract_methods)
        result.merge(methods) if methods
      end

      result.to_a
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
    # : (method_name : Symbol) -> Bool
    def abstract_method_declared?(method_name)
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
    #       Foo.new.instance_method # Might *will* AbstractMethodNotImplementedError
    #     end
    #
    #     if Foo.singleton_class.abstract_method?(:class_method)
    #       Foo.class_method # Might *will* AbstractMethodNotImplementedError
    #     end
    #
    # : (method_name : Symbol) -> Bool
    def abstract_method?(method_name)
      # If the method is defined, it has a concrete implementation, so it's not abstract.
      return false if method_defined?(method_name) || private_method_defined?(method_name)

      abstract_method_declared?(method_name)
    end
  end

  module AbstractClassMethodReceiver
    # This method_missing is hit when calling a potentially abstract method on a class that contains abstract methods
    # E.g. TheClass.maybe_abstract_method
    def method_missing(method_name, ...)
      if singleton_class.abstract_method_declared?(method_name)
        raise AbstractMethodNotImplementedError, "Abstract method #{method_name.inspect} was never implemented."
      end

      raise "This doesn't make sense" if singleton_class.abstract_method?(method_name) # sanity check

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      # TODO: handle visibility properly

      singleton_class.abstract_method_declared?(method_name) || super
    end
  end

  # A module that's included on a class, whose instances can be receivers of calls to abstract methods.
  module AbstractInstanceMethodReceiver
    # This `#method_missing` is hit when calling a potentially abstract method on an instance
    # E.g. TheClass.new.maybe_abstract_method
    def method_missing(method_name, ...)
      if self.class.abstract_method_declared?(method_name)
        raise AbstractMethodNotImplementedError, "Abstract method #{method_name.inspect} was never implemented."
      end

      raise "This doesn't make sense" if self.class.abstract_method?(method_name) # sanity check

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      # TODO: handle visibility properly

      self.class.abstract_method_declared?(method_name) || super
    end
  end
end
