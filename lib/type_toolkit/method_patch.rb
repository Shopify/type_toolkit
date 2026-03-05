# typed: strict
# frozen_string_literal: true

module TypeToolkit
  # @requires_ancestor: MethodOrUnboundMethod
  module MethodPatch
    # Returns true if this method is an abstract method that hasn't been implemented.
    # Calling it will raise an `AbstractMethodNotImplementedError`.
    #: -> bool
    def abstract?
      return false unless TypeToolkit::HasAbstractMethods === (owner = self.owner)

      owner.abstract_method?(name)
    end
  end
end
