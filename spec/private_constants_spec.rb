# typed: ignore
# frozen_string_literal: true

require "spec_helper"

module TypeToolkit
  class PrivateConstantsSpec < Minitest::Spec
    class WithPrivateConstants
      private_constants do
        SECRET = 123
        ANOTHER_SECRET = 456
      end

      PUBLIC_CONSTANT = 789

      class << self
        def secret = SECRET
      end
    end

    class WithNestedPrivateConstant
      private_constants do
        class Inner
        end
      end
    end

    describe "Module#private_constants" do
      it "marks every constant defined within the block as private" do
        assert_raises(NameError) { WithPrivateConstants::SECRET }
        assert_raises(NameError) { WithPrivateConstants::ANOTHER_SECRET }
      end

      it "still allows the defining scope to reference the constant unqualified" do
        assert_equal 123, WithPrivateConstants.secret
      end

      it "does not affect constants defined outside the block" do
        assert_equal 789, WithPrivateConstants::PUBLIC_CONSTANT
      end

      it "works for constants defined via the `class`/`module` keywords, not just `=`" do
        assert_raises(NameError) { WithNestedPrivateConstant::Inner }
      end

      it "does not raise when the block defines no new constants" do
        WithPrivateConstants.private_constants {}
      end

      it "propagates exceptions raised inside the block" do
        assert_raises(RuntimeError) do
          Module.new do
            private_constants do
              raise "boom"
            end
          end
        end
      end
    end
  end
end
