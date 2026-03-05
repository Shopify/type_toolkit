# typed: ignore
# frozen_string_literal: true

# This benchmarks compares the cost of patching `new` vs `allocate`, in order to pick the best
# technique to raise an error when instantiating an abstract class.

############################################# Results #############################################
#
# ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin23]
#
# |                    | Interpretter |      YJIT |
# |--------------------|-------------:|----------:|
# | PatchingNew_NoArgs |    147.36 ns | 108.85 ns |
# | PatchingNew        |    152.52 ns | 117.19 ns |
# | PatchingAllocate   |    128.18 ns |  88.85 ns |
#
####################################################################################################

require "bundler"
Bundler.require(:default, :benchmark)

require "type_toolkit"
require "type_toolkit/ext"

# The forwarding of arguments might skew results, so let's compare patching a 0-arity `new`
# for a more equal comparison to to `allocate` (which is already 0-arity).
module PatchingNew_NoArgs
  class Parent
    def self.new = Parent.equal?(self) ? raise("Cannot instantiate abstract class") : super
  end

  class Child < Parent
    def self.new = super
  end
end

module PatchingNew
  class Parent
    def self.new(...) = Parent.equal?(self) ? raise("Cannot instantiate abstract class") : super
  end

  class Child < Parent
    def self.new(...) = super
  end
end

module PatchingNew_NoArgs_Reimpl
  class Parent
    def self.new = Parent.equal?(self) ? raise("Cannot instantiate abstract class") : allocate.send(:initialize)
  end

  class Child < Parent
    def self.new = super
  end
end

module PatchingNew_Reimpl
  class Parent
    def self.new(...) = Parent.equal?(self) ? raise("Cannot instantiate abstract class") : allocate.send(:initialize, ...)
  end

  class Child < Parent
    def self.new(...) = super
  end
end

module ReimplViaModule_NoArgs
  module NewReimpl
    def new(...)
      allocate.send(:initialize, ...)
    end
  end

  class Parent
    def self.new(...) = raise("Cannot instantiate abstract class")
  end

  class Child < Parent
    extend NewReimpl

    def self.new(...) = super
  end
end

module ReimplViaModule
  module NewReimpl
    def new(...)
      allocate.send(:initialize, ...)
    end
  end

  class Parent
    def self.new(...) = raise("Cannot instantiate abstract class")
  end

  class Child < Parent
    extend NewReimpl

    def self.new(...) = super
  end
end


module PatchingAllocate
  class Parent
    def self.allocate = Parent.equal?(self) ? raise("Cannot instantiate abstract class") : super
  end

  class Child < Parent
    def self.allocate = super
  end
end

# Enable and start GC before each job run. Disable GC afterwards.
#
# Inspired by https://www.omniref.com/ruby/2.2.1/symbols/Benchmark/bm?#annotation=4095926&line=182
class GCSuite
  def warming(*)
    run_gc
  end

  def running(*)
    run_gc
  end

  def warmup_stats(*)
  end

  def add_report(*)
  end

  private

  def run_gc
    GC.enable
    GC.start
    GC.disable
  end
end

suite = GCSuite.new

[:interpretter, :yjit].each do |mode|
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
  suite = GCSuite.new

  width = ["PatchingNew_NoArgs_Reimpl", "ReimplViaModule_NoArgs", "PatchingAllocate"].max_by(&:length).length

  puts "Benchmark the performance of calling the concrete implementation directly..."
  Benchmark.ips do |x|
    x.config(warmup:, time:, suite:)

    x.report("PatchingNew_NoArgs".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        PatchingNew_NoArgs::Child.new
      end
    end

    x.report("PatchingNew".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        PatchingNew::Child.new
      end
    end

    x.report("PatchingNew_NoArgs_Reimpl".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        PatchingNew_NoArgs_Reimpl::Child.new
      end
    end

    x.report("PatchingNew_Reimpl".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        PatchingNew_Reimpl::Child.new
      end
    end

    x.report("ReimplViaModule_NoArgs".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        ReimplViaModule_NoArgs::Child.new
      end
    end

    x.report("ReimplViaModule".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        ReimplViaModule::Child.new
      end
    end

    x.report("PatchingAllocate".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        PatchingAllocate::Child.allocate
      end
    end

    x.compare!
  end
end
