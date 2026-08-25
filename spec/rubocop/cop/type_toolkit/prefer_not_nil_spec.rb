# typed: true
# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/minitest/assert_offense"
require "rubocop-type_toolkit"

module RuboCop
  module Cop
    module TypeToolkit
      class PreferNotNilSpec < ::Minitest::Spec
        include RuboCop::Minitest::AssertOffense

        MSG = "TypeToolkit/PreferNotNil: Use `.not_nil!` instead of `T.must()`."

        before do
          @cop = PreferNotNil.new
        end

        it "autocorrects T.must" do
          assert_offense(<<~RUBY)
            value = T.must(foo)
                    ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = foo.not_nil!
          RUBY
        end

        it "autocorrects ::T.must" do
          assert_offense(<<~RUBY)
            value = ::T.must(foo)
                    ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = foo.not_nil!
          RUBY
        end

        it "autocorrects inside string interpolation" do
          assert_offense(<<~RUBY)
            string = "\#{T.must(foo)}"
                        ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            string = "\#{foo.not_nil!}"
          RUBY
        end

        it "preserves the precedence of conditional and range expressions" do
          assert_offense(<<~RUBY)
            conditional = T.must(condition ? foo : bar)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            range = T.must(foo..bar)
                    ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            conditional = (condition ? foo : bar).not_nil!
            range = (foo..bar).not_nil!
          RUBY
        end

        it "parenthesizes every expression that requires it" do
          assert_offense(<<~RUBY)
            operator = T.must(foo + bar)
                       ^^^^^^^^^^^^^^^^^ #{MSG}
            logical = T.must(foo || bar)
                      ^^^^^^^^^^^^^^^^^^ #{MSG}
            grouped = T.must((foo || bar))
                      ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            assignment = T.must(foo = bar)
                         ^^^^^^^^^^^^^^^^^ #{MSG}
            block_value = T.must(foo { bar })
                          ^^^^^^^^^^^^^^^^^^^ #{MSG}
            defined_value = T.must(defined?(foo))
                            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            def example
              T.must(yield foo)
              ^^^^^^^^^^^^^^^^^ #{MSG}
            end
            def implicit_super
              T.must(super)
              ^^^^^^^^^^^^^ #{MSG}
            end
            def explicit_super
              T.must(super(foo))
              ^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            operator = (foo + bar).not_nil!
            logical = (foo || bar).not_nil!
            grouped = (foo || bar).not_nil!
            assignment = (foo = bar).not_nil!
            block_value = (foo { bar }).not_nil!
            defined_value = (defined?(foo)).not_nil!
            def example
              (yield foo).not_nil!
            end
            def implicit_super
              (super).not_nil!
            end
            def explicit_super
              (super(foo)).not_nil!
            end
          RUBY
        end

        it "preserves the precedence of command calls" do
          assert_offense(<<~RUBY)
            value = T.must(fetch value)
                    ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = (fetch value).not_nil!
          RUBY
        end

        it "does not add unnecessary parentheses to parenthesized calls" do
          assert_offense(<<~RUBY)
            value = T.must(fetch(value))
                    ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = fetch(value).not_nil!
          RUBY
        end

        it "parenthesizes bracket method calls only when required" do
          assert_offense(<<~RUBY)
            bracketed = T.must(foo[bar]).foo
                        ^^^^^^^^^^^^^^^^ #{MSG}
            explicit = T.must(foo.[](bar)).foo
                       ^^^^^^^^^^^^^^^^^^^ #{MSG}
            command = T.must(foo.[] bar).foo
                      ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            bracketed = foo[bar].not_nil!.foo
            explicit = foo.[](bar).not_nil!.foo
            command = (foo.[] bar).not_nil!.foo
          RUBY
        end

        it "preserves comments in multiline calls" do
          assert_offense(<<~RUBY)
            value = T.must(
                    ^^^^^^^ #{MSG}
              # Proven non-nil by validation.
              foo,
            )
          RUBY

          assert_correction(<<~RUBY)
            value = (
              # Proven non-nil by validation.
              foo
            ).not_nil!
          RUBY
        end

        it "autocorrects multiline calls with whitespace before the method" do
          assert_offense(<<~RUBY)
            first = T .must(
                    ^^^^^^^^ #{MSG}
              foo,
            )
            second = T
                     ^ #{MSG}
              .must(
                bar,
              )
          RUBY

          assert_correction(<<~RUBY)
            first = (
              foo
            ).not_nil!
            second = (
                bar
              ).not_nil!
          RUBY
        end

        it "removes a trailing comma before an inline comment" do
          assert_offense(<<~RUBY)
            value = T.must(
                    ^^^^^^^ #{MSG}
              foo, # Proven non-nil.
            )
          RUBY

          assert_correction(<<~RUBY)
            value = (
              foo # Proven non-nil.
            ).not_nil!
          RUBY
        end

        it "autocorrects nested T.must calls" do
          assert_offense(<<~RUBY)
            value = T.must(T.must(foo).bar)
                    ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                           ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = foo.not_nil!.bar.not_nil!
          RUBY
        end

        it "autocorrects three nested T.must calls" do
          assert_offense(<<~RUBY)
            value = T.must(T.must(T.must(foo).bar).baz)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                           ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                                  ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            value = foo.not_nil!.bar.not_nil!.baz.not_nil!
          RUBY
        end

        it "ignores other receivers, methods, and argument counts" do
          assert_no_offenses(<<~RUBY)
            Other::T.must(foo)
            object.must(foo)
            T.let(foo, String)
            T.must(foo, bar)
            T.must(*values)
          RUBY
        end
      end
    end
  end
end
