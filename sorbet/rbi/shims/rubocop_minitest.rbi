# typed: true
# frozen_string_literal: true

module RuboCop
  module Minitest
    module AssertOffense
      sig { params(source: String).void }
      def assert_offense(source); end

      sig { params(source: String).void }
      def assert_no_offenses(source); end

      sig { params(source: String).void }
      def assert_correction(source); end
    end
  end
end
