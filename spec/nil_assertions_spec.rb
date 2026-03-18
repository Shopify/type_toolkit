# typed: true
# frozen_string_literal: true

require "spec_helper"
require "sorbet-runtime"

module TypeToolkit
  class NilAssertionsTest < Minitest::Spec
    describe "#not_nil!" do
      extend T::Sig

      it "returns self on non-nil values" do
        x = "Hello, world!"
        assert_same x, x.not_nil!
      end

      it "raises an error on nil values" do
        assert_raises(UnexpectedNilError) { nil.not_nil! }
      end

      it "raises an error on Sorbet runtime's void value" do
        # Cast away the void type to prevent the static type checker from blocking this with
        # "Cannot call method `not_nil!` on void type"
        void_value = example_void_returner #: as Object

        assert_same T::Private::Types::Void::VOID, void_value
        e = assert_raises(UnexpectedNilError) { void_value.not_nil! }

        # Do not rely on this message content! Its content is subject to change.
        assert_includes e.message, "Called `not_nil!` on a void value (T::Private::Types::Void::VOID)"
      end

      private

      # To make sure we're patching the right thing, use a void-returning method to produce a void value,
      # rather than directly referencing `T::Private::Types::Void::VOID`.
      sig { void }
      def example_void_returner = nil
    end
  end
end
