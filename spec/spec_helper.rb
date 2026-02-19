# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "type_toolkit"

require "minitest/autorun"
require "minitest/spec"

module Minitest
  class Spec
    #: () { () -> void } -> TypeToolkit::AbstractMethodNotImplementedError
    def assert_abstract(&block)
      assert_raises(TypeToolkit::AbstractMethodNotImplementedError, &block)
    end
  end
end

#: -> bot
def assert_never_called!
  raise Minitest::Assertion, "This should never be called"
end
