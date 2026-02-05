# typed: strict
# frozen_string_literal: true

class Class
  #: -> void
  def abstract!
    TypeToolkit.make_abstract!(self)
  end
end
