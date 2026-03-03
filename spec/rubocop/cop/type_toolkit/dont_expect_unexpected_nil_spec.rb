# typed: true
# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/minitest/assert_offense"
require "rubocop-type_toolkit"

module RuboCop
  module Cop
    module TypeToolkit
      class DontExpectUnexpectedNilSpec < ::Minitest::Spec
        CONSTANT_NAMES = [
          "UnexpectedNilError",
          "::UnexpectedNilError",
          "TypeToolkit::UnexpectedNilError",
          "::TypeToolkit::UnexpectedNilError",
        ].freeze

        include RuboCop::Minitest::AssertOffense

        before do
          @cop = DontExpectUnexpectedNil.new
        end

        describe "assert_raises" do
          CONSTANT_NAMES.each do |constant_name|
            arrows_______ = "^" * constant_name.size

            describe constant_name do
              it "adds offense with a { } block" do
                assert_offense(<<~RUBY)
                  assert_raises(#{constant_name}) { foo }
                  ^^^^^^^^^^^^^^#{arrows_______}^ #{assert_raises_message}
                RUBY
              end

              it "adds offense with a do ... end block" do
                assert_offense(<<~RUBY)
                  assert_raises(#{constant_name}) do
                  ^^^^^^^^^^^^^^#{arrows_______}^ #{assert_raises_message}
                    foo
                  end
                RUBY
              end

              it "adds offense when passed among other arguments" do
                assert_offense(<<~RUBY)
                  assert_raises(ArgumentError, #{constant_name}) { foo }
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#{arrows_______}^ #{assert_raises_message}
                RUBY

                assert_offense(<<~RUBY)
                  assert_raises(#{constant_name}, ArgumentError) { foo }
                  ^^^^^^^^^^^^^^#{arrows_______}^^^^^^^^^^^^^^^^ #{assert_raises_message}
                RUBY
              end
            end
          end

          it "does not add offense when assert_raises is used with a different error" do
            assert_no_offenses(<<~RUBY)
              assert_raises(ArgumentError) { foo }
            RUBY
          end
        end

        describe "rescue" do
          CONSTANT_NAMES.each do |constant_name|
            arrows_______ = "^" * constant_name.size

            describe constant_name do
              it "adds offense" do
                assert_offense(<<~RUBY)
                  begin
                    foo
                  rescue #{constant_name}
                         #{arrows_______} #{rescue_message}
                    bar
                  end
                RUBY
              end

              it "adds offense when among other exceptions" do
                assert_offense(<<~RUBY)
                  begin
                    foo
                  rescue #{constant_name}, ArgumentError
                         #{arrows_______} #{rescue_message}
                    bar
                  end
                RUBY
              end
            end
          end

          it "does not add offense when rescuing other exceptions" do
            assert_no_offenses(<<~RUBY)
              begin
                foo
              rescue ArgumentError
                bar
              end
            RUBY
          end
        end

        describe "raise" do
          CONSTANT_NAMES.each do |constant_name|
            arrows_______ = "^" * constant_name.size

            describe constant_name do
              it "adds offense" do
                assert_offense(<<~RUBY)
                  raise #{constant_name}
                  ^^^^^^#{arrows_______} #{raise_message}
                RUBY
              end

              it "adds offense with a message" do
                assert_offense(<<~RUBY)
                  raise #{constant_name}, "message"
                  ^^^^^^#{arrows_______}^^^^^^^^^^^ #{raise_message}
                RUBY
              end

              it "adds offense with .new" do
                assert_offense(<<~RUBY)
                  raise #{constant_name}.new
                  ^^^^^^#{arrows_______}^^^^ #{raise_message}
                RUBY
              end

              it "adds offense with .new and a message" do
                assert_offense(<<~RUBY)
                  raise #{constant_name}.new, "message"
                  ^^^^^^#{arrows_______}^^^^^^^^^^^^^^^ #{raise_message}
                RUBY
              end
            end
          end

          it "does not add offense when raising other exceptions" do
            assert_no_offenses(<<~RUBY)
              raise ArgumentError
            RUBY
          end
        end

        describe "other usages of UnexpectedNilError" do
          CONSTANT_NAMES.each do |constant_name|
            arrows_______ = "^" * constant_name.size

            it "adds offense when using #{constant_name}" do
              assert_offense(<<~RUBY)
                x = #{constant_name}
                    #{arrows_______} #{general_usage_message}
              RUBY
            end
          end

          it "does not add offense when using other constants" do
            assert_no_offenses(<<~RUBY)
              x = ArgumentError
              x = ::ArgumentError
            RUBY
          end
        end

        private

        def assert_raises_message
          "TypeToolkit/DontExpectUnexpectedNil: It is always a mistake for `not_nil!` to be called on nil, " \
            "so tests should not expect any code to raise `UnexpectedNilError`. " \
            "Change your code to gracefully handle `nil` instead."
        end

        def rescue_message
          "TypeToolkit/DontExpectUnexpectedNil: It is always a mistake for `not_nil!` to be called on nil, " \
            "so you should never try to rescue `UnexpectedNilError` specifically. " \
            "Change your code to gracefully handle `nil` instead."
        end

        def raise_message
          "TypeToolkit/DontExpectUnexpectedNil: `UnexpectedNilError` should only ever be raised by `NilClass#not_nil!`."
        end

        def general_usage_message
          "TypeToolkit/DontExpectUnexpectedNil: `UnexpectedNilError` should only ever be used by `#not_nil!`."
        end
      end
    end
  end
end
