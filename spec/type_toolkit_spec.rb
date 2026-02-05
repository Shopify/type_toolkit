# frozen_string_literal: true

require "spec_helper"

module TypeToolkit
  class TypeToolkitSpec < Minitest::Spec
    it "has a version number" do
      refute_nil ::TypeToolkit::VERSION
    end
  end
end
