require 'socket'

data = Array.new(16 * 16 / 8) { (rand * 255).round }
puts data.inspect

100.times do
  s = TCPSocket.new('localhost', 5001)
  s.binmode
  s.write(data.pack('c' * data.size))
  s.close

  sleep 0.1
end

