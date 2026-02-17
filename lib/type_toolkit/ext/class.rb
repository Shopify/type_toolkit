# frozen_string_literal: true

class Class
  def abstract!
    p(new)
    # # We need to save the original implementation of `new`, so we can restore it on the subclasses later.
    singleton_class.alias_method(:__original_new_impl, :new)

    extend(TypeToolkit::AbstractClass)
    extend(TypeToolkit::DSL)
    extend(TypeToolkit::MethodDefRecorder)
    extend(TypeToolkit::HasAbstractMethods)

    # TODO: move this to the `abstract` macro.
    include(TypeToolkit::AbstractInstanceMethodReceiver)
  end
end
