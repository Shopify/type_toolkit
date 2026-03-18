# typed: ignore
# frozen_string_literal: true

# This file is `typed: ignore` so we don't have to implement the abstract methods from `T::Types::Base`,
# which `sorbet-runtime` will implement eventually anyway.

require "bundler"
return unless Bundler.locked_gems.specs.any? { |s| s.name == "sorbet-runtime" }

module TypeToolkit
  module SorbetRuntimeCompatibility
    module VoidPatch
      # An override of `not_nil!` intended to reduce the discrepancy between test and production environments
      # when Sorbet Runtime is used in tests but not production.
      #
      # When Sorbet Runtime is active `void`-returning methods have their return value replaced with the
      # `T::Private::Types::Void::VOID` module. If Sorbet Runtime is on in tests but not production,
      # this introduces a dangerous difference in behaviour for methods that return `nil`:
      #
      # * In test code, it'll be replaced with `T::Private::Types::Void::VOID`.
      #   If `not_nil!` is called on it (and this override didn't exist), it'll just return `self`.
      #
      # * In production code, that `nil` value will left-as-is, and calling `not_nil!` on it will raise an error.
      #: -> bot
      def not_nil!
        # Do not rely on this message content! Its content is subject to change.
        raise TypeToolkit::UnexpectedNilError, "Called `not_nil!` on a void value (T::Private::Types::Void::VOID)"
      end
    end
  end
end

module T
  module Types
    class Base; end
  end

  module Private
    module Types
      class Void < T::Types::Base
        if defined?(::T::Private::Types::Void::VOID)
          # sorbet-runtime was already loaded, and the `VOID` module is already frozen, so we can't change it.
          # Instead, replace it with our own copy.
          ::T::Private::Types::Void.const_set(:VOID, ::Module.new do
            extend ::TypeToolkit::SorbetRuntimeCompatibility::VoidPatch

            freeze # Freeze it like the original
          end)
        else
          # sorbet-runtime hasn't been loaded yet, so we're defining the `VOID` module for the first time.
          module VOID
            extend ::TypeToolkit::SorbetRuntimeCompatibility::VoidPatch
            # Leave it unfrozen so sorbet-runtime can freeze it later when it defines it.
          end
        end
      end
    end
  end
end
