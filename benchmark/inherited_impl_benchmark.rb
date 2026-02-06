# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "type_toolkit"
require "type_toolkit/ext"

require "sorbet-runtime"

module AbstractGemDemo
  # Provides the concrete implementation of `m`
  class Parent
    def m = :parent_implementation
  end

  module I
    interface!

    abstract def m; end
    abstract def not_implemented; end
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    extend TypeToolkit::MethodDefRecorder

    include TypeToolkit::AbstractInstanceMethodReceiver
    extend TypeToolkit::HasAbstractMethods

    include I
  end
end

module SorbetRuntimeDemo
  # Provides the concrete implementation of `m`
  class Parent
    def m = :parent_implementation
  end

  module I
    extend T::Sig
    extend T::Helpers

    interface!

    sig { abstract.returns(String) }
    def m; end

    sig { abstract.returns(String) }
    def not_implemented; end
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    include I
  end
end

module ManualDelegationDemo
  class Parent
    def m = :parent_implementation
  end

  module I
    def m = defined?(super) ? super : raise

    def not_implemented = defined?(super) ? super : raise
  end

  # Inherits the concrete implementation of `m` from DemoParentClass.
  class Child < Parent
    include I
  end
end

abstract_gem_parent_instance = AbstractGemDemo::Parent.new
abstract_gem_child_instance = AbstractGemDemo::Child.new

sorbet_runtime_parent_instance = SorbetRuntimeDemo::Parent.new
sorbet_runtime_child_instance = SorbetRuntimeDemo::Child.new

manual_delegation_parent_instance = ManualDelegationDemo::Parent.new
manual_delegation_child_instance = ManualDelegationDemo::Child.new

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

  width = ["abstract gem", "sorbet-runtime", "manual delegation"].max_by(&:length).length

  puts "Benchmark the performance of calling the concrete implementation directly..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("abstract gem".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        abstract_gem_parent_instance.m
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        sorbet_runtime_parent_instance.m
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        manual_delegation_parent_instance.m
      end
    end

    x.compare!
  end

  puts "\n\nBenchmark the performance of calling the inherited concrete implementation..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("abstract gem".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        abstract_gem_child_instance.m
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        sorbet_runtime_child_instance.m
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        manual_delegation_child_instance.m
      end
    end

    x.compare!
  end

  puts "\n\nTest the performance of calling an unimplemented abstract method..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("abstract gem".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          abstract_gem_child_instance.not_implemented
        rescue AbstractMethodNotImplementedError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.report("sorbet-runtime".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          sorbet_runtime_child_instance.not_implemented
        rescue NotImplementedError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.report("manual delegation".rjust(width)) do |times|
      i = 0
      while (i += 1) < times
        begin
          manual_delegation_child_instance.not_implemented
        rescue StandardError # rubocop:disable Lint/SuppressedException
        end
      end
    end

    x.compare!
  end
end
