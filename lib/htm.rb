
require 'ffi-rzmq'
require 'socket'
require 'celluloid'

require 'enumerable'

require 'htm/version'
require 'htm/config'
require 'htm/logging'
require 'htm/errors'
require 'htm/geometry'
require 'htm/dispatcher'
require 'htm/network'
require 'htm/region'
require 'htm/column'
require 'htm/cell'
require 'htm/input_cell'
require 'htm/synapse'
require 'htm/dendrite_segment'

Thread.abort_on_exception = true

module HTM
  def version
    VERSION
  end
  module_function :version
end
