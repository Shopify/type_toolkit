# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "type_toolkit"

require "minitest/autorun"
require "minitest/spec"

module Minitest
  class Spec
    def assert_abstract(&block)
      assert_raises(AbstractMethodNotImplementedError, &block)
    end
  end
end

def assert_never_called!
  raise Minitest::Assertion, "This should never been called"
end
