# typed: false
# frozen_string_literal: true

require "lint_roller"
require "type_toolkit/version"

module RuboCop
  module Cop
    module TypeToolkit
      class Plugin < LintRoller::Plugin
        def about
          LintRoller::About.new(
            name: "rubocop-type_toolkit",
            version: ::TypeToolkit::VERSION,
            homepage: "https://github.com/Shopify/type_toolkit",
            description: "Detects misuse of UnexpectedNilError.",
          )
        end

        def supported?(context)
          context.engine == :rubocop
        end

        def rules(_context)
          LintRoller::Rules.new(
            type: :path,
            config_format: :rubocop,
            value: Pathname.new(__dir__).join("../../../../config/default.yml"),
          )
        end
      end
    end
  end
end
