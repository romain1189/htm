require 'htm'
require 'benchmark'

region = HTM::Region.new
Benchmark.bmbm do |x|
  x.report("iteration") {
    region.tick(Array.new(region.input_size) { rand.round })
  }
end
