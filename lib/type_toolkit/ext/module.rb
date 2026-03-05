# frozen_string_literal: true

class Module
  def interface!
    TypeToolkit.make_interface!(self)
  end
end
