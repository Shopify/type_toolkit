# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"

module M1; end
module M2; end
class C1; end
class C2; end

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

  puts "Benchmark the performance of calling the concrete implementation directly..."
  Benchmark.ips do |x|
    x.config(warmup:, time:)

    x.report("check then include") do |times|
      i = 0
      while (i += 1) < times
        C1.include(M1) unless C1.include?(M1)
      end
    end

    x.report("just include") do |times|
      i = 0
      while (i += 1) < times
        C2.include(M2)
      end
    end

    x.compare!
  end
end
