# frozen_string_literal: true

class Class
  def abstract!
    TypeToolkit.make_abstract!(self)
  end
end
