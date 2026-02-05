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
    def __register_abstract_method(method_name) # :nodoc:
      (@__abstract_methods ||= Set.new) << method_name
    end

    # Returns all methods that were marked abstract (even those which are implemented).
    def declared_abstract_instance_methods(include_super = true)
      result = @__abstract_methods

      return result.to_a unless include_super

      if defined?(super) && (super_abstract_methods = super)
        result.merge(super_abstract_methods)
      end

      abstract_methods_in_interfaces = included_modules.flat_map do |m|
        m.is_a?(HasAbstractMethods) ? m.declared_abstract_instance_methods : []
      end

      if abstract_methods_in_interfaces.any?
        if result&.any?
          result.merge(abstract_methods_in_interfaces)
        else
          result = abstract_methods_in_interfaces
        end
      end

      result.to_a
    end

    # Returns all methods that are abstract and have not been implemented.
    def abstract_instance_methods(include_super = true)
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
    def abstract_method_declared?(method_name)
      @__abstract_methods&.include?(method_name) ||
        included_modules.any? { |m| m.is_a?(HasAbstractMethods) && m.abstract_method_declared?(method_name) } ||
        (defined?(super) && super)
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
    def abstract_method?(method_name)
      # If the method is defined, it has a concrete implementation, so it's not abstract.
      return false if method_defined?(method_name) || private_method_defined?(method_name)

      abstract_method_declared?(method_name)
    end
  end
end
