# frozen_string_literal: true

require "spec_helper"

module TypeToolkit
  module Misc
    # This test just characterizes how `method_added` hooks work. It doesn't have anything to do with TypeToolkit itself,
    # but it's useful for devs to confirm how this works across instance and class methods.
    class HowMethodAddedHooksWorkSpec < Minitest::Spec
      it "characterizes how method_added hooks work" do
        test_context = self

        Class.new do
          class << self
            attr_reader :__last_method_def

            class << self
              def __last_method_def
                attached_object.__last_method_def
              end
            end

            def method_added(m)
              is_singleton_method = false
              @__last_method_def = [m, is_singleton_method]

              super
            end

            def singleton_method_added(m)
              return super if m == :singleton_method_added

              is_singleton_method = true
              @__last_method_def = [m, is_singleton_method]

              super
            end
          end

          test_context.assert_nil __last_method_def

          def instance_method; end

          test_context.assert_equal [:instance_method, false], __last_method_def

          def self.singleton_method_via_self_dot; end # rubocop:disable Style/ClassMethodsDefinitions

          test_context.assert_equal [:singleton_method_via_self_dot, true], __last_method_def

          r = class << self
                def singleton_method_via_sclass; end

                __last_method_def
          end

          test_context.assert_equal [:singleton_method_via_sclass, true], r

          test_context.assert_equal [:singleton_method_via_sclass, true], __last_method_def
        end
      end
    end
  end
end
