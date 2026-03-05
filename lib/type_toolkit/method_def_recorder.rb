# typed: strict
# frozen_string_literal: true

module TypeToolkit
  # This module tracks new methods being defined, and whether they were
  # instance methods (`def foo; end`) or singleton methods (`def self.foo; end`).
  module MethodDefRecorder
    #: [Symbol, bool]?
    attr_reader :__last_method_def

    class << self
      #: (Module[top]) -> void
      def extended(target_module)
        # Also extend the singleton class so methods are available there
        target_module.singleton_class.extend(ClassMethods)
      end
    end

    # These actually go on the YourClass.singleton_class.singleton_class
    # @requires_ancestor: MethodDefRecorder
    module ClassMethods
      #: () -> [Symbol, bool]?
      def __last_method_def
        #: self as Class[MethodDefRecorder]
        cls = attached_object #: as MethodDefRecorder
        cls.__last_method_def
      end
    end

    # Need `@without_runtime` because of https://github.com/Shopify/tapioca/issues/2513
    # @without_runtime
    #: (Symbol) -> void
    def method_added(m)
      is_singleton_method = false
      @__last_method_def = [m, is_singleton_method] #: [Symbol, bool]?

      super
    end

    # Need `@without_runtime` because of https://github.com/Shopify/tapioca/issues/2513
    # @without_runtime
    # @override
    #: (Symbol) -> void
    def singleton_method_added(m)
      return super if m == :singleton_method_added

      is_singleton_method = true
      @__last_method_def = [m, is_singleton_method] #: [Symbol, bool]?

      super
    end
  end
end
