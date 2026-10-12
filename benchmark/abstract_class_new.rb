# typed: ignore
# frozen_string_literal: true

# Benchmark the time it takes to instantiate a subclass of an abstract class

############################################# Results #############################################
#
# ruby 4.0.0 (2025-12-25 revision 553f1675f3) +PRISM [arm64-darwin23]
#
# Time to instantiate a subclass of an abstract class
# |                   |              Interpreter |                    YJIT |
# |-------------------|-------------------------:|------------------------:|
# | sorbet-runtime    |                118.95 ns |                97.93 ns |
# | type_toolkit      |  (3.32x faster) 35.82 ns | (4.63x faster) 21.14 ns |
#
# Time to instantiate a subclass of an abstract class with a custom implementation of `new`
# |                   |              Interpreter |                    YJIT |
# |-------------------|-------------------------:|------------------------:|
# | sorbet-runtime    |                140.45 ns |               119.00 ns |
# | type_toolkit      | (1.17x faster) 119.89 ns | (1.40x faster) 84.75 ns |
#
####################################################################################################

require "bundler"
Bundler.setup(:default, :benchmark)
Bundler.require(:benchmark)

# Intentionally not requiring "type_toolkit/ext/class", so we don't monkey-patch in our `Class#abstract!`.
# If we did, Sorbet runtime's `abstract!` would call it (since delegates up the chain), and break things.
require "type_toolkit/abstract_class"

# This benchmark has pretty high variance (it depends on the GC's allocation patterns),
# so we run it for a longer time to get a more stable result.
warmup = 10
time = 30

width = ["type_toolkit", "sorbet-runtime", "manual delegation"].max_by(&:length).length

module TypeKitDemo
  class Parent
    TypeToolkit.make_abstract!(self)
  end

  class Child < Parent; end

  class Child_OverridesNew < Parent
    def self.new(...) = super
  end
end

module SorbetRuntimeDemo
  class Parent
    extend T::Helpers

    abstract!
  end

  class Child < Parent; end

  class Child_OverridesNew < Parent
    def self.new(...) = super
  end
end

# Run GC before each job run.
#
# Inspired by https://www.omniref.com/ruby/2.2.1/symbols/Benchmark/bm?#annotation=4095926&line=182
class GCSuite
  def warming(*)
    GC.start
  end

  def running(*)
    GC.start
  end

  def warmup_stats(*)
  end

  def add_report(*)
  end
end

suite = GCSuite.new

[:interpreter, :yjit].each do |mode|
  if mode == :yjit
    puts <<~MSG


      ================================================================================
      Enabling YJIT...
      ================================================================================


    MSG
    RubyVM::YJIT.enable
  end

  puts "\nBenchmark the time to instantiate a subclass of an abstract class..."
  Benchmark.ips do |x|
    x.config(warmup:, time:, suite:)

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        SorbetRuntimeDemo::Child.new
      end
    end

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        TypeKitDemo::Child.new
      end
    end

    x.compare!(order: :baseline)
  end

  puts "\nBenchmark the time to instantiate a subclass of an abstract class with a custom implementation of `new`..."
  Benchmark.ips do |x|
    x.config(warmup:, time:, suite:)

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        SorbetRuntimeDemo::Child_OverridesNew.new
      end
    end

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        TypeKitDemo::Child_OverridesNew.new
      end
    end

    x.compare!(order: :baseline)
  end
end
