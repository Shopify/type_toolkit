# typed: strict
# frozen_string_literal: true

# A shim module representing (a subset of) the common interface between Method and UnboundMethod.
module MethodOrUnboundMethod
  sig { returns(T::Module[T.untyped]) }
  def owner; end

  sig { returns(Symbol) }
  def name; end
end

class Method
  include MethodOrUnboundMethod
end

class UnboundMethod
  include MethodOrUnboundMethod
end
