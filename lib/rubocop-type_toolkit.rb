# frozen_string_literal: true

require "rubocop"

RuboCop::ConfigLoader.inject_defaults!(File.join(__dir__, "..", "config", "default.yml"))

require_relative "rubocop/cop/type_toolkit/dont_expect_unexpected_nil"
