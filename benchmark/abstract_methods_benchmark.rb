# typed: ignore
# frozen_string_literal: true

# Benchmark the performance overhead of calling:
# - A concrete implementation of an abstract method
# - An inherited concrete implementation of an abstract method
# - The error case of calling an unimplemented abstract method

############################################# Results #############################################
#
# ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin23]
#
# ## Interpreter
#
# | Call to...        |        Regular impl |          Inherited impl |              Missing impl |
# |-------------------|--------------------:|------------------------:|--------------------------:|
# | sorbet-runtime    | (same-ish) 23.02 ns | (2.70x slower) 57.30 ns | (1.13x  slower) 472.86 ns |
# | manual delegation | (same-ish) 22.18 ns | (2.07x slower) 44.90 ns |               *415.36 ns* |
# | type_toolkit      | (same-ish) 22.56 ns |              *22.03 ns* | (2.11x  slower) 890.38 ns |
#
# ## YJIT#
# | Call to...        |        Regular impl |           Inherited impl |              Missing impl |
# |-------------------|--------------------:|-------------------------:|--------------------------:|
# | sorbet-runtime    |  (same-ish) 1.63 ns | (21.41x slower) 34.91 ns | (1.10x  slower) 447.59 ns |
# | manual delegation |  (same-ish) 1.63 ns |  (7.15x slower) 11.66 ns |               *405.84 ns* |
# | type_toolkit      |  (same-ish) 1.67 ns |                *1.63 ns* | (1.91x  slower) 774.91 ns |
#
####################################################################################################

require "bundler"
Bundler.require(:default, :benchmark)

require "type_toolkit"

module TypeKitDemo
  # Provides the concrete implementation of `m`
  class Parent
    def m1 = "Parent#m1"
  end

  module I
    interface!

    abstract def m1; end
    abstract def m2; end
    abstract def not_implemented; end
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    include I

    def m2 = "Child#m2"
  end
end

module SorbetRuntimeDemo
  # Provides the concrete implementation of `m`
  class Parent
    def m1 = "Parent#m1"
  end

  module I
    extend T::Sig
    extend T::Helpers

    interface!

    sig { abstract.returns(String) }
    def m1; end

    sig { abstract.returns(String) }
    def m2; end

    sig { abstract.returns(String) }
    def not_implemented; end
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    include I

    def m2 = "Child#m2"
  end
end

module ManualDelegationDemo
  class Parent
    def m1 = "Parent#m1"
  end

  module I
    def m1 = defined?(super) ? super : raise
    def m2 = defined?(super) ? super : raise
    def not_implemented = defined?(super) ? super : raise
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    include I

    def m2 = "Child#m2"
  end
end

type_toolkit_object = TypeKitDemo::Child.new
manual_delegation_object = ManualDelegationDemo::Child.new
sorbet_runtime_object = SorbetRuntimeDemo::Child.new

[:interpreter, :yjit].each do |mode|
  if mode == :yjit
    puts <<~MSG


      ================================================================================
      Enabling YJIT...
      ================================================================================


    MSG
    RubyVM::YJIT.enable
  end

  warmup = 5
  time = 10

  width = ["type_toolkit", "sorbet-runtime", "manual delegation"].max_by(&:length).length

  puts "Benchmark the performance of calling the concrete implementation directly..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        type_toolkit_object.m2
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        sorbet_runtime_object.m2
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        manual_delegation_object.m2
      end
    end

    x.compare!
  end

  puts "\n\nBenchmark the performance of calling the inherited concrete implementation..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        type_toolkit_object.m1
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        sorbet_runtime_object.m1
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        manual_delegation_object.m1
      end
    end

    x.compare!
  end

  puts "\n\nTest the performance of calling an unimplemented abstract method..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          type_toolkit_object.not_implemented
        rescue AbstractMethodNotImplementedError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          sorbet_runtime_object.not_implemented
        rescue NotImplementedError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          manual_delegation_object.not_implemented
        rescue StandardError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.compare!
  end
end
