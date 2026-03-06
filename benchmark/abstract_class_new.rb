# typed: ignore
# frozen_string_literal: true

# Benchmark the time it takes to instantiate a subclass of an abstract class

############################################# Results #############################################
#
# ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin23]
#
# Time to instantiate a subclass of an abstract class
# |                   |              Interpreter |                     YJIT |
# |-------------------|-------------------------:|-------------------------:|
# | sorbet-runtime    | (2.29x slower) 109.28 ns |  (2.49x slower) 90.09 ns |
# | type_toolkit      |                 47.80 ns |                 36.23 ns |
#
# Time to instantiate a subclass of an abstract class with a custom implementation of `new`
# |                   |              Interpreter |                     YJIT |
# |-------------------|-------------------------:|-------------------------:|
# | sorbet-runtime    | (1.10x slower) 132.95 ns | (1.32x slower) 104.45 ns |
# | type_toolkit      |                121.12 ns |                 79.33 ns |
#
####################################################################################################

require "bundler"
Bundler.require(:default, :benchmark)

require "type_toolkit"

# This benchmark has pretty high variance (it depends on the GC's allocation patterns),
# so we run it for a longer time to get a more stable result.
warmup = 10
time = 30

width = ["type_toolkit", "sorbet-runtime", "manual delegation"].max_by(&:length).length

# module PreventConflictingAbstractPatch
#   def abstract!
#     # Prevent Sorbet's definition of `abstract!` from calling the TypeToolkit implementation of `abstract!`
#     return if singleton_class.include?(T::Helpers)

#     super
#   end
# end

# Class.prepend(PreventConflictingAbstractPatch)

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

    # binding.irb
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
    x.config(warmup:, time:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        TypeKitDemo::Child.new
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        SorbetRuntimeDemo::Child.new
      end
    end

    x.compare!
  end

  puts "\nBenchmark the time to instantiate a subclass of an abstract class with a custom implementation of `new`..."
  Benchmark.ips do |x|
    x.config(warmup:, time:, suite:)

    x.report("type_toolkit".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        TypeKitDemo::Child_OverridesNew.new
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        SorbetRuntimeDemo::Child_OverridesNew.new
      end
    end

    x.compare!
  end
end
