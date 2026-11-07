# typed: true
# frozen_string_literal: true

module RuboCop
  module Minitest
    module AssertOffense
      sig { params(source: String, file: T.nilable(String), replacements: String).void }
      def assert_offense(source, file = nil, **replacements); end

      sig { params(source: String).void }
      def assert_no_offenses(source); end

      sig { params(source: String).void }
      def assert_correction(source); end

      sig { void }
      def assert_no_corrections; end
    end
  end
end
