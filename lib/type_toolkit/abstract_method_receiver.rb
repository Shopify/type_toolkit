# typed: true
# frozen_string_literal: true

module TypeToolkit
  # Raised when a call is made to an abstract method that never had a real implementation.
  class AbstractMethodNotImplementedError < Exception # rubocop:disable Lint/InheritException
    def initialize(method_name:)
      # Do not rely on this message content! Its content is subject to change.
      super("Abstract method `##{method_name}` was never implemented.")
    end
  end

  # This module is included on a class whose instances can be receivers of calls to abstract methods.
  #
  # Since abstract methods are removed at runtime (see `TypeToolkit::DSL#abstract`), attempting to call
  # an unimplemented abstract method would usually raise a `NoMethodError`.
  # This module uses `method_missing` to raise `AbstractMethodNotImplementedError` instead.
  # @requires_ancestor: Kernel
  module AbstractInstanceMethodReceiver
    # This `#method_missing` is hit when calling a potentially abstract method on an instance
    # E.g. TheClass.new.maybe_abstract_method
    #
    # We call `super` first, so that another `method_missing` further up the ancestor chain
    # gets a chance to provide a dynamic implementation of the abstract method.
    # Only if nothing handled the call do we translate the resulting `NoMethodError`
    # into an `AbstractMethodNotImplementedError`.
    #
    # (Symbol, ...) -> untyped
    def method_missing(method_name, ...)
      super
    rescue NoMethodError => e
      # A `NoMethodError` for a *different* method was raised from within a dynamic
      # implementation of this method. That's a real error, not an unimplemented abstract method.
      raise unless e.name == method_name

      c = self.class #: as Class[top] & HasAbstractMethods

      if c.abstract_method_declared?(method_name)
        # `cause: nil` hides the unactionable "undefined method" error, which would
        # otherwise be noise underneath the more precise error we raise here.
        raise AbstractMethodNotImplementedError.new(method_name:), cause: nil
      end

      raise
    end

    #: (Symbol, ?bool) -> bool
    def respond_to_missing?(method_name, include_private = false)
      self.class.abstract_method_declared?(method_name) || super
    end
  end
end
