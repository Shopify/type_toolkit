# typed: true
# frozen_string_literal: true

module RuboCop
  module Cop
    module TypeToolkit
      # This cop detects attempts to raise, rescue, or otherwise use the `UnexpectedNilError` class.
      class DontExpectUnexpectedNil < Base
        RESTRICT_ON_SEND = [:assert_raises, :raise].freeze

        #: (RuboCop::AST::SendNode) -> void
        def on_send(node)
          case node.method_name
          # when :raise then check_raise(node)
          when :assert_raises then check_assert_raises(node)
          end
        end

        #: (RuboCop::AST::ResbodyNode) -> void
        def on_resbody(node)
          if (rescued_cls = node.exceptions.find { |ex_class| ex_class.const_type? && unexpected_nil_error?(ex_class) })
            message = "It is always a mistake for `not_nil!` to be called on nil, " \
              "so you should never try to rescue `UnexpectedNilError` specifically. " \
              "Change your code to gracefully handle `nil` instead."
            add_offense(rescued_cls, message:)
            ignore_const_node(rescued_cls)
          end
        end

        # This is a catch-all for cases where the `UnexpectedNilError` class is used outside of a raise, rescue, etc.
        #: (RuboCop::AST::ConstNode) -> void
        def on_const(node)
          # Don't report this node right away, in case its parent AST is reported by one of the other cases.
          # Instead, record it for now, and maybe report it at the end of the investigation.
          if unexpected_nil_error?(node)
            @const_read_nodes ||= Set.new.compare_by_identity
            @const_read_nodes << node
          end
        end

        # @override
        #: -> void
        def on_investigation_end
          @const_read_nodes&.each do |node|
            next if @ignored_const_nodes&.include?(node)

            message = "`UnexpectedNilError` should only ever be used by `#not_nil!`."
            add_offense(node, message:)
          end

          super
        end

        private

        #: (RuboCop::AST::ConstNode) -> bool
        def unexpected_nil_error?(node)
          node.short_name == :UnexpectedNilError && (node.namespace.nil? || node.namespace.cbase_type?)
        end

        # Check for `raise UnexpectedNilError`
        #: (RuboCop::AST::SendNode) -> void
        def check_raise(node)
          constant = case (first_arg = node.arguments.first)
          when RuboCop::AST::ConstNode
            node.arguments.first
          when RuboCop::AST::SendNode
            return unless first_arg.method_name == :new && first_arg.receiver.const_type?

            first_arg.receiver
          else return
          end

          if unexpected_nil_error?(constant)
            message = "`UnexpectedNilError` should only ever be raised by `NilClass#not_nil!`."
            add_offense(node, message:)
            ignore_const_node(constant)
          end
        end

        # Check for `assert_raises UnexpectedNilError`
        #: (RuboCop::AST::SendNode) -> void
        def check_assert_raises(node)
          if (constants = node.arguments.filter { |arg| arg.const_type? && unexpected_nil_error?(arg) }).any?
            message = "It is always a mistake for `not_nil!` to be called on nil, " \
              "so tests should not expect any code to raise `UnexpectedNilError`. " \
              "Change your code to gracefully handle `nil` instead."
            add_offense(node, message:)
            ignore_const_node(*constants)
          end
        end

        # Call this when this constant node is part of a node tree that already has an offense.
        # This way we don't report a second offense for the same constant.
        #: (*RuboCop::AST::ConstNode) -> void
        def ignore_const_node(*nodes)
          @ignored_const_nodes ||= Set.new.compare_by_identity
          @ignored_const_nodes.merge(nodes)
        end
      end
    end
  end
end
