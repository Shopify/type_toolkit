# typed: true
# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/minitest/assert_offense"
require "rubocop-type_toolkit"

module RuboCop
  module Cop
    module TypeToolkit
      describe DontExpectUnexpectedNil do
        include RuboCop::Minitest::AssertOffense

        before do
          @cop = DontExpectUnexpectedNil.new
        end

        describe "assert_raises" do
          describe "UnexpectedNilError" do
            it "adds offense with a { } block" do
              assert_offense(<<~RUBY)
                assert_raises(UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end

            it "adds offense with a do ... end block" do
              assert_offense(<<~RUBY)
                assert_raises(UnexpectedNilError) do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
                  foo
                end
              RUBY
            end

            it "adds offense when passed among other arguments" do
              assert_offense(<<~RUBY)
                assert_raises(ArgumentError, UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY

              assert_offense(<<~RUBY)
                assert_raises(UnexpectedNilError, ArgumentError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end
          end

          describe "::UnexpectedNilError" do
            it "adds offense with a { } block" do
              assert_offense(<<~RUBY)
                assert_raises(::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end

            it "adds offense with a do ... end block" do
              assert_offense(<<~RUBY)
                assert_raises(::UnexpectedNilError) do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
                  foo
                end
              RUBY
            end

            it "adds offense when passed among other arguments" do
              assert_offense(<<~RUBY)
                assert_raises(::UnexpectedNilError, ArgumentError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY

              assert_offense(<<~RUBY)
                assert_raises(ArgumentError, ::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end
          end

          describe "TypeToolkit::UnexpectedNilError" do
            it "adds offense with a { } block" do
              assert_offense(<<~RUBY)
                assert_raises(TypeToolkit::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end

            it "adds offense with a do ... end block" do
              assert_offense(<<~RUBY)
                assert_raises(TypeToolkit::UnexpectedNilError) do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
                  foo
                end
              RUBY
            end

            it "adds offense when passed among other arguments" do
              assert_offense(<<~RUBY)
                assert_raises(TypeToolkit::UnexpectedNilError, ArgumentError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY

              assert_offense(<<~RUBY)
                assert_raises(ArgumentError, TypeToolkit::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end
          end

          describe "::TypeToolkit::UnexpectedNilError" do
            it "adds offense with a { } block" do
              assert_offense(<<~RUBY)
                assert_raises(::TypeToolkit::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end

            it "adds offense with a do ... end block" do
              assert_offense(<<~RUBY)
                assert_raises(::TypeToolkit::UnexpectedNilError) do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
                  foo
                end
              RUBY
            end

            it "adds offense when passed among other arguments" do
              assert_offense(<<~RUBY)
                assert_raises(::TypeToolkit::UnexpectedNilError, ArgumentError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY

              assert_offense(<<~RUBY)
                assert_raises(ArgumentError, ::TypeToolkit::UnexpectedNilError) { foo }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{assert_raises_message}
              RUBY
            end
          end

          it "does not add offense when assert_raises is used with a different error" do
            assert_no_offenses(<<~RUBY)
              assert_raises(ArgumentError) { foo }
            RUBY
          end
        end

        describe "rescue" do
          describe "UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue UnexpectedNilError
                       ^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end

            it "adds offense when among other exceptions" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue UnexpectedNilError, ArgumentError
                       ^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end
          end

          describe "::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue ::UnexpectedNilError
                       ^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end

            it "adds offense when among other exceptions" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue ::UnexpectedNilError, ArgumentError
                       ^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end
          end

          describe "TypeToolkit::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue TypeToolkit::UnexpectedNilError
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end

            it "adds offense when among other exceptions" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue TypeToolkit::UnexpectedNilError, ArgumentError
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end
          end

          describe "::TypeToolkit::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue ::TypeToolkit::UnexpectedNilError
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
            end

            it "adds offense when among other exceptions" do
              assert_offense(<<~RUBY)
                begin
                  foo
                rescue ::TypeToolkit::UnexpectedNilError, ArgumentError
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{rescue_message}
                  bar
                end
              RUBY
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
          describe "UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                raise UnexpectedNilError
                ^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with a message" do
              assert_offense(<<~RUBY)
                raise UnexpectedNilError, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new" do
              assert_offense(<<~RUBY)
                raise UnexpectedNilError.new
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new and a message" do
              assert_offense(<<~RUBY)
                raise UnexpectedNilError.new, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end
          end

          describe "::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                raise ::UnexpectedNilError
                ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with a message" do
              assert_offense(<<~RUBY)
                raise ::UnexpectedNilError, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new" do
              assert_offense(<<~RUBY)
                raise ::UnexpectedNilError.new
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new and a message" do
              assert_offense(<<~RUBY)
                raise ::UnexpectedNilError.new, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end
          end

          describe "TypeToolkit::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                raise TypeToolkit::UnexpectedNilError
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with a message" do
              assert_offense(<<~RUBY)
                raise TypeToolkit::UnexpectedNilError, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new" do
              assert_offense(<<~RUBY)
                raise TypeToolkit::UnexpectedNilError.new
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new and a message" do
              assert_offense(<<~RUBY)
                raise TypeToolkit::UnexpectedNilError.new, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end
          end

          describe "::TypeToolkit::UnexpectedNilError" do
            it "adds offense" do
              assert_offense(<<~RUBY)
                raise ::TypeToolkit::UnexpectedNilError
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with a message" do
              assert_offense(<<~RUBY)
                raise ::TypeToolkit::UnexpectedNilError, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new" do
              assert_offense(<<~RUBY)
                raise ::TypeToolkit::UnexpectedNilError.new
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end

            it "adds offense with .new and a message" do
              assert_offense(<<~RUBY)
                raise ::TypeToolkit::UnexpectedNilError.new, "message"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{raise_message}
              RUBY
            end
          end

          it "does not add offense when raising other exceptions" do
            assert_no_offenses(<<~RUBY)
              raise ArgumentError
            RUBY
          end
        end

        describe "other usages of UnexpectedNilError" do
          it "adds offense when using UnexpectedNilError" do
            assert_offense(<<~RUBY)
              x = UnexpectedNilError
                  ^^^^^^^^^^^^^^^^^^ #{general_usage_message}
            RUBY
          end

          it "adds offense when using ::UnexpectedNilError" do
            assert_offense(<<~RUBY)
              x = ::UnexpectedNilError
                  ^^^^^^^^^^^^^^^^^^^^ #{general_usage_message}
            RUBY
          end

          it "adds offense when using TypeToolkit::UnexpectedNilError" do
            assert_offense(<<~RUBY)
              x = TypeToolkit::UnexpectedNilError
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{general_usage_message}
            RUBY
          end

          it "adds offense when using ::TypeToolkit::UnexpectedNilError" do
            assert_offense(<<~RUBY)
              x = ::TypeToolkit::UnexpectedNilError
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{general_usage_message}
            RUBY
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
