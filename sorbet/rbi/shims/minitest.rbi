# typed: strict
# frozen_string_literal: true

module Minitest
  class Spec < Minitest::Test
    extend Minitest::Spec::DSL

    include RuboCop::Minitest::AssertOffense

    sig do
      params(
        desc: T.anything,
        block: T.proc.bind(T.self_type).void,
      ).void
    end
    def it(desc = T.unsafe(nil), &block); end

    module DSL
      has_attached_class!(:out)

      sig do
        params(
          desc: T.anything,
          block: T.proc.bind(T.attached_class).void,
        ).void
      end
      def describe(desc, &block); end

      sig do
        params(
          desc: T.anything,
          block: T.proc.bind(T.attached_class).void,
        ).void
      end
      def it(desc = T.unsafe(nil), &block); end

      sig do
        params(block: T.proc.bind(T.attached_class).void).void
      end
      def before(&block); end
    end
  end
end
