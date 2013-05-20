$:.push File.expand_path('../../lib', __FILE__)

require 'htm'

HTM::Network.node('localhost', 5002, 'localhost', 5003)
