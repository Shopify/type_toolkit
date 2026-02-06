# frozen_string_literal: true

# Benchmark if it's worth checking `Module.include?` before calling`Module.include`
# ... spoiler: meh, not really.

############################################# Results #############################################
#
# ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin23]
#
# |                    |             Interpreter |                    YJIT |
# |-------------------:|------------------------:|------------------------:|
# |       just include | (2.39x slower) 54.35 ns | (8.53x slower) 35.29 ns |
# | check then include |                22.72 ns |                 4.14 ns |
#
####################################################################################################

require "bundler"
Bundler.require(:default, :benchmark)

module M1; end
module M2; end
class C1; end
class C2; end

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
