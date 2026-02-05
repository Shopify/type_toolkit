# typed: true
# frozen_string_literal: true

module TypeToolkit
  # Raised when a call is made to an abstract method that never had a real implementation.
  class AbstractMethodNotImplementedError < Exception # rubocop:disable Lint/InheritException
    def initialize(method_name:, is_class_method:)
      qualifier = is_class_method ? "class " : ""
      prefix = is_class_method ? "." : "#"
      # Do not rely on this message content! Its content is subject to change.
      super("Abstract #{qualifier}method `#{prefix}#{method_name}` was never implemented.")
    end
  end

  # This module is included on a class whose instances can be receivers of calls to abstract methods.
  #
  # This is just like `AbstractClassMethodReceiver`, but with a performance optimization to call `self.class`
  # instead of `singleton_class`.
  # In theory we could just always use implementation from `AbstractClassMethodReceiver`,
  # but touching the `singleton_class` would allocate the singleton class for every object that hits the `#method_missing` code path.
  # @requires_ancestor: Kernel
  module AbstractInstanceMethodReceiver
    # This `#method_missing` is hit when calling a potentially abstract method on an instance
    # E.g. TheClass.new.maybe_abstract_method
    #
    # (Symbol, ...) -> untyped
    def method_missing(method_name, ...)
      c = self.class #: as Class[top] & HasAbstractMethods

      if c.abstract_method_declared?(method_name)
        raise AbstractMethodNotImplementedError.new(method_name:, is_class_method: false)
      end

      super
    end

    #: (Symbol, ?bool) -> bool
    def respond_to_missing?(method_name, include_private = false)
      self.class.abstract_method_declared?(method_name) || super
    end
  end
end
