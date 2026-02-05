# frozen_string_literal: true

class Class
  def abstract!
    extend(TypeToolkit::DSL)
    extend(TypeToolkit::MethodDefRecorder)
    extend(TypeToolkit::HasAbstractMethods)

    # TODO: move this to the `abstract` macro.
    include(TypeToolkit::AbstractInstanceMethodReceiver)
  end
end
