# typed: true
# frozen_string_literal: true

module RuboCop
  module Cop
    module TypeToolkit
      # Replaces Sorbet's `T.must(value)` assertion with Type Toolkit's `value.not_nil!` assertion.
      class PreferNotNil < Base
        extend AutoCorrector

        MSG = "Use `.not_nil!` instead of `T.must()`."
        RESTRICT_ON_SEND = [:must].freeze

        COMMA_BYTE = ",".ord
        private_constant :COMMA_BYTE

        KEYWORD_EXPRESSION_TYPES = [:defined?, :super, :yield, :zsuper].freeze
        private_constant :KEYWORD_EXPRESSION_TYPES

        #: (RuboCop::AST::SendNode) -> void
        def on_send(node)
          return unless (argument = extract_t_must_argument(node))

          if nested_t_must?(node)
            add_offense(node, message: MSG)
          else
            replacement = replacement_for(argument)
            correction = correction_for(node, argument, replacement)

            add_offense(node, message: MSG) do |corrector|
              corrector.replace(node, correction)
            end
          end
        end

        private

        #: (RuboCop::AST::SendNode) -> RuboCop::AST::Node?
        def extract_t_must_argument(node)
          receiver = node.receiver
          return unless receiver.is_a?(RuboCop::AST::ConstNode)
          return unless receiver.short_name == :T && node.method?(:must) && node.arguments.one?

          namespace = receiver.namespace
          return unless namespace.nil? || namespace.cbase_type?

          argument = node.first_argument
          return unless argument
          return if argument.splat_type? || argument.kwsplat_type?

          argument
        end

        #: (RuboCop::AST::Node) -> String
        def replacement_for(argument)
          source = argument.source

          source = "(#{source})" if requires_parentheses?(argument)

          "#{source}.not_nil!"
        end

        #: (RuboCop::AST::SendNode, RuboCop::AST::Node, String) -> String
        def correction_for(node, argument, replacement)
          return replacement unless node.multiline? && node.parenthesized_call?
          return replacement if argument.first_line == node.loc.begin.line && argument.last_line == node.loc.end.line

          grouped_range = node.source_range.with(begin_pos: node.loc.begin.begin_pos, end_pos: node.loc.end.end_pos)
          grouped_source = grouped_range.source
          comma_offset = argument.source_range.end_pos - grouped_range.begin_pos
          grouped_source.slice!(comma_offset) if grouped_source.getbyte(comma_offset) == COMMA_BYTE
          "#{grouped_source}.not_nil!"
        end

        #: (RuboCop::AST::SendNode) -> bool
        def nested_t_must?(node)
          node.each_ancestor(:send).any? do |ancestor|
            ancestor.is_a?(RuboCop::AST::SendNode) && extract_t_must_argument(ancestor)
          end
        end

        #: (RuboCop::AST::Node) -> bool
        def requires_parentheses?(argument)
          return false if argument.begin_type?

          if argument.is_a?(RuboCop::AST::SendNode)
            return bracket_call_requires_parentheses?(argument) if argument.method?(:[])
            return true if argument.operator_method?
            return true if argument.arguments? && !argument.parenthesized_call?
          end
          return true if argument.range_type? || argument.operator_keyword?
          return true if argument.if_type? || argument.assignment?
          return true if argument.any_block_type?

          KEYWORD_EXPRESSION_TYPES.include?(argument.type)
        end

        # `foo[bar]` and `foo.[](bar)` can be chained directly, but command-style `foo.[] bar` cannot.
        #: (RuboCop::AST::SendNode) -> bool
        def bracket_call_requires_parentheses?(argument)
          argument.dot? && !argument.parenthesized_call?
        end
      end
    end
  end
end
