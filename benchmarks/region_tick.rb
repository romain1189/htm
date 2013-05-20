$:.push File.expand_path('../../lib', __FILE__)

require 'htm'
require 'benchmark'

n = 10

region = HTM::Region.new
data = n.times.map { Array.new(region.input_size) { rand.round } }

Benchmark.bmbm do |x|
  x.report("iteration") {
    n.times { |i| region.tick(data[i]) }
  }
end
