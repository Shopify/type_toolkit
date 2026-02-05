# frozen_string_literal: true

class Module
  def interface!
    extend(TypeToolkit::Interface)
    extend(TypeToolkit::DSL)
    extend(TypeToolkit::MethodDefRecorder)
    extend(TypeToolkit::HasAbstractMethods)
  end

  # Syntactic sugar
  def implements(interface)
    include(interface)
  end
end
