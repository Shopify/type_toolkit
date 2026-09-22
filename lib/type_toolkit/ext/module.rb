# typed: true
# frozen_string_literal: true

class Module
  def interface!
    TypeToolkit.make_interface!(self)
  end

  # Marks every constant defined directly within the block as private.
  #
  # Constants don't respect `private`/`public` regions the way methods do, so making one private
  # normally means repeating its name in a separate `private_constant` call. This bundles that up
  # into a single block, so you don't have to.
  #
  # Example:
  #
  #   class Configuration
  #     private_constants do
  #       DEFAULT_TIMEOUT = 30
  #     end
  #   end
  #
  #   Configuration::DEFAULT_TIMEOUT
  #   # => NameError: private constant Configuration::DEFAULT_TIMEOUT referenced
  #
  #: () { () -> void } -> void
  def private_constants(&block)
    constants_before = constants(false)
    yield
    new_constants = constants(false) - constants_before
    new_constants.each { |constant_name| private_constant(constant_name) }
  end
end
