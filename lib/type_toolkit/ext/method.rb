# frozen_string_literal: true

require "type_toolkit/method_patch"

class Method
  prepend TypeToolkit::MethodPatch
end

class UnboundMethod
  prepend TypeToolkit::MethodPatch
end
