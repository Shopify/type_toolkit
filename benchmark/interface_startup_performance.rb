# typed: ignore
# frozen_string_literal: true

# Benchmark the startup performance of declaring modules/interfaces in 3 different styles:
# - TypeToolkit (abstract gem)
# - Sorbet runtime
# - Manual delegation (defined?(super) pattern)

############################################# Results #############################################
#
# ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin23]
#
# |                   |              Interpreter |                       YJIT |
# |-------------------|-------------------------:|---------------------------:|
# | sorbet-runtime    | (21.34x slower) 50.79 μs | (152.34x slower) 377.27 μs |
# | type_toolkit      |  (4.18x slower)  9.95 μs |   (4.18x slower)  10.35 μs |
# | manual delegation |                  2.38 μs |                    2.48 μs |
#
####################################################################################################

require "bundler"
Bundler.require(:default, :benchmark)

require "type_toolkit"

warmup = 5
time = 10

width = ["type_toolkit", "sorbet-runtime", "manual delegation"].max_by(&:length).length

puts "Benchmark the time to declare an interface module with abstract methods..."

[:interpreter, :yjit].each do |mode|
  if mode == :yjit
    puts <<~MSG


      ================================================================================
      Enabling YJIT...
      ================================================================================


    MSG
    RubyVM::YJIT.enable
  end

  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        interface = Module.new do
          interface!

          abstract def m1; end
          abstract def m2; end
          abstract def m3; end
        end

        Class.new do
          include interface

          def m1 = "m1"
          def m2 = "m2"
          def m3 = "m3"
        end
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        interface = Module.new do
          extend T::Sig
          extend T::Helpers

          interface!

          sig { abstract.returns(String) }
          def m1; end

          sig { abstract.returns(String) }
          def m2; end

          sig { abstract.returns(String) }
          def m3; end
        end

        Class.new do
          extend T::Sig

          include interface

          sig { override.returns(String) }
          def m1 = "m1"

          sig { override.returns(String) }
          def m2 = "m2"

          sig { override.returns(String) }
          def m3 = "m3"
        end
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        interface = Module.new do
          def m1 = defined?(super) ? super : raise
          def m2 = defined?(super) ? super : raise
          def m3 = defined?(super) ? super : raise
        end

        Class.new do
          include interface

          def m1 = "m1"
          def m2 = "m2"
          def m3 = "m3"
        end
      end
    end

    x.compare!
  end
end
