require 'socket'

receiver = TCPServer.new('localhost', 5002)

run = true

trap('INT') { run = false; exit }

while run
  socket = receiver.accept
  socket.binmode
  result = socket.read
  socket.close

  puts "received #{result.unpack('c' * result.size)}"
end
