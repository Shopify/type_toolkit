# typed: true
# frozen_string_literal: true

module RuboCop
  module Cop
    module TypeToolkit
      # Replaces Sorbet's `T.must` and `T.must_because` assertions with `.not_nil!`.
      class PreferNotNil < Base
        extend AutoCorrector

        MSG = "Use `.not_nil!` instead of `T.%<method>s()`."
        RESTRICT_ON_SEND = [:must, :must_because].freeze

        COMMA_BYTE = ",".ord
        private_constant :COMMA_BYTE

        KEYWORD_EXPRESSION_TYPES = [:defined?, :super, :yield, :zsuper].freeze
        private_constant :KEYWORD_EXPRESSION_TYPES

        #: (RuboCop::AST::SendNode) -> void
        def on_send(node)
          return unless (argument = extract_assertion_argument(node))

          block = node.block_node if node.method?(:must_because)
          target = block || node
          message = format(MSG, method: node.method_name)

          if nested_assertion?(node) || (block && contains_heredoc?(block))
            add_offense(target, message:)
          else
            replacement = replacement_for(argument)
            correction = correction_for(node, argument, replacement)
            correction = commented_correction(block, correction) if block

            add_offense(target, message:) do |corrector|
              corrector.replace(target, correction)
            end
          end
        end

        private

        #: (RuboCop::AST::SendNode) -> RuboCop::AST::Node?
        def extract_assertion_argument(node)
          receiver = node.receiver
          return unless receiver.is_a?(RuboCop::AST::ConstNode)
          return unless receiver.short_name == :T && RESTRICT_ON_SEND.include?(node.method_name) && node.arguments.one?

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
          return replacement unless comments_inside_parentheses?(node) || contains_heredoc?(argument)

          grouped_range = node.source_range.with(begin_pos: node.loc.begin.begin_pos, end_pos: node.loc.end.end_pos)
          grouped_source = grouped_range.source
          comma_offset = argument.source_range.end_pos - grouped_range.begin_pos
          grouped_source.slice!(comma_offset) if grouped_source.getbyte(comma_offset) == COMMA_BYTE
          "#{grouped_source}.not_nil!"
        end

        #: (RuboCop::AST::Node) -> bool
        def contains_heredoc?(node)
          return true if node.loc.is_a?(Parser::Source::Map::Heredoc)

          node.each_descendant(:any_str).any? do |descendant|
            descendant.loc.is_a?(Parser::Source::Map::Heredoc)
          end
        end

        #: (RuboCop::AST::SendNode) -> bool
        def comments_inside_parentheses?(node)
          contents_begin = node.loc.begin.end_pos
          contents_end = node.loc.end.begin_pos

          processed_source.comments.any? do |comment|
            comment_range = comment.loc.expression
            contents_begin <= comment_range.begin_pos && comment_range.end_pos <= contents_end
          end
        end

        #: (RuboCop::AST::SendNode) -> bool
        def nested_assertion?(node)
          node.each_ancestor(:send, :block, :numblock, :itblock).any? do |ancestor|
            send_node = ancestor.is_a?(RuboCop::AST::SendNode) ? ancestor : ancestor.send_node
            !send_node.equal?(node) && send_node.is_a?(RuboCop::AST::SendNode) && extract_assertion_argument(send_node)
          end
        end

        #: (RuboCop::AST::BlockNode, String) -> String
        def commented_correction(block, correction)
          indentation = block.source_range.source_line[/\A\s*/]
          reason_range = block.source_range.with(
            begin_pos: block.loc.begin.end_pos,
            end_pos: block.loc.end.begin_pos,
          )
          reason = reason_range.source
          body = block.body
          if body && (body.str_type? || body.dstr_type?) && ["\"", "'"].include?(body.loc.begin&.source)
            reason.slice!(body.loc.end.begin_pos - reason_range.begin_pos)
            reason.slice!(body.loc.begin.begin_pos - reason_range.begin_pos)
          end
          comments = reason.strip.lines.map { |line| "#{indentation}  # #{line.strip}\n" }.join
          return "(\n#{comments}#{correction.delete_prefix("(\n")}" if correction.start_with?("(\n")

          "(\n#{comments}#{indentation}  #{correction}\n#{indentation})"
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
