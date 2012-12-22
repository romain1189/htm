require 'celluloid'

require 'enumerable'

require 'htm/version'
require 'htm/config'
require 'htm/logger'
require 'htm/network'
require 'htm/region'
require 'htm/column'
require 'htm/cell'
require 'htm/synapse'
require 'htm/dendrite_segment'

module HTM
  class << self
    attr_accessor :logger
  end
  @logger = Logger.new(STDOUT)

  def version
    VERSION
  end
  module_function :version
end
