# typed: true
# frozen_string_literal: true

require "spec_helper"

module TypeToolkit
  class NilAssertionsTest < Minitest::Spec
    describe "#not_nil!" do
      it "returns self on non-nil values" do
        x = "Hello, world!"
        assert_same x, x.not_nil!
      end

      it "raises an error on nil values" do
        assert_raises(UnexpectedNilError) { nil.not_nil! }
      end
    end
  end
end
