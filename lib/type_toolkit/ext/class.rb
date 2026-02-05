# typed: strict
# frozen_string_literal: true

require "type_toolkit/abstract_class"

class Class
  #: -> void
  def abstract!
    TypeToolkit.make_abstract!(self)
  end
end
