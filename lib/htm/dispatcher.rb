module HTM
  class Dispatcher
    include Logging

    #
    #
    # @todo better method arguments
    def initialize(host, port, parent_host, parent_port, \
                   ipc_address = nil, parent_ipc_address = nil)

      @ipc_address = ipc_address if ipc_address
      @parent_ipc_address = parent_ipc_address if parent_ipc_address

      @receiver = TCPServer.new(host, port)

      @parent_host, @parent_port = parent_host, parent_port

      @run = false
    end

    def run
      @run = true
      loop do
        client = @receiver.accept
        client.binmode
        input = client.read
        client.close

        unless input.nil?
          result = yield input.unpack('c' * input.size)

          result.each do |output|
            sender = TCPSocket.new(@parent_host, @parent_port)
            sender.binmode
            sender.write(output.pack('c' * output.size))
            sender.close
          end
        end
        break unless @run
      end
    end

    def stop
      @run = false
    end
  end
end


# module HTM
#   class Dispatcher
#     include Logging

#     #
#     #
#     # @todo better method arguments
#     def initialize(host, port, parent_host = nil, parent_port = nil,
#                    ipc_address = nil, parent_ipc_address = nil)

#       @context = ZMQ::Context.new(1)
#       raise DispatcherError, "Failed to create a ZMQ context" unless @context

#       @host = host
#       @parent_host = parent_host
#       @port = port
#       @parent_port = parent_port

#       @ipc_address = ipc_address if ipc_address
#       @parent_ipc_address = parent_ipc_address if parent_ipc_address

#       @receiver = @context.socket(ZMQ::PULL)
#       @sender = @context.socket(ZMQ::PUSH)

#       @run = false
#     end

#     def run
#       code = @receiver.bind("tcp://#{@host}:#{@port}")
#       raise error if error?(code)
#       if @ipc_address
#         code = @receiver.bind("ipc://#{@ipc_address}.ipc")
#         raise_unless(ZMQ::EPROTONOSUPPORT) if error?(code)
#       end

#       code = @sender.connect("tcp://#{@parent_host}:#{@parent_port}")
#       raise error if error?(code)
#       if @parent_ipc_address
#         code = @sender.connect("ipc://#{@parent_ipc_address}.ipc")
#         raise_unless(ZMQ::EPROTONOSUPPORT) if error?(code)
#       end

#       @run = true
#       loop do
#         buffer = ''
#         code = @receiver.recv_string(buffer)
#         raise error if error?(code)

#         result = yield buffer.unpack('c')

#         code = @sender.send_string(result.pack('c'))
#         raise error if error?(code)

#         break unless @run
#       end

#       code = @receiver.close
#       code = @sender.close

#       @context.terminate
#     end

#     def stop
#       @run = false
#     end

#     private

#     def error?(code)
#       ZMQ::Util.resultcode_ok?(code)
#     end

#     def raise_unless(*codes)
#       case ZMQ::Util.errno
#       when *codes
#         warn ("Operation failed, errno [#{ZMQ::Util.errno}] " \
#         + "description [#{ZMQ::Util.error_string}]")
#       else
#         raise error
#       end
#     end

#     def error
#       DispatcherError.new("Operation failed, errno [#{ZMQ::Util.errno}] " \
#         + "description [#{ZMQ::Util.error_string}]")
#     end
#   end
# end
