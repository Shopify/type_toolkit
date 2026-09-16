# frozen_string_literal: true

class Module
  def interface!
    TypeToolkit.make_interface!(self)
  end

  def abstract!
    super if defined?(super)
    TypeToolkit.make_abstract!(self)
  end
end
