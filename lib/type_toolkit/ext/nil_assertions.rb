# typed: true
# frozen_string_literal: true

# Asserts that the receiver is not nil.
#
# You should use `not_nil!` in places where you're absolutely sure a `nil` value can't occur.
# This should be done as closely to where the value is created as possible, so that the `nil`
# value doesn't have a chance to be passed around the system. This way, failures occur close to
# the source of the problem, and are easier to fix.
module Kernel
  #: -> self
  def not_nil!
    self
  end
end

class NilClass
  # @override
  #: -> bot
  def not_nil!
    raise TypeToolkit::UnexpectedNilError
  end
end

module TypeToolkit
  # An error raised when calling `#not_nil!` on a `nil` value.
  #
  # `UnexpectedNilError` should never occur in well-formed code, so it should never be rescued.
  # This is why it inherits from `Exception` instead of `StandardError`,
  # so that bare rescue clauses (like `rescue => e`) don't accidentally swallow it.
  #
  # Note: `rescue Exception` can still catch it, but that's intentionally harder to write accidentally.
  class UnexpectedNilError < Exception # rubocop:disable Lint/InheritException
    def initialize(message = "Called `not_nil!` on nil.")
      super
    end
  end
end
