# frozen_string_literal: true

module TypeToolkit
  # This module tracks new methods being defined, and whether they were
  # instance methods (`def foo; end`) or singleton methods (`def self.foo; end`).
  module MethodDefRecorder
    attr_reader :__last_method_def

    class << self
      def extended(target_module)
        # Also extend the singleton class so methods are available there
        target_module.singleton_class.extend(ClassMethods)
      end
    end

    # These actually go on the YourClass.singleton_class.singleton_class
    module ClassMethods
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
end
