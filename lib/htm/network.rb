module HTM
  module Network
    def node(host, port, parent_host, parent_port, ipc_host = nil, parent_ipc_host = nil)
      region = Region.new(column_width: 4, column_height: 4, input_width: 16, \
                         input_height: 16)

      dispatcher = Dispatcher.new(host, port, parent_host, parent_port, ipc_host, parent_ipc_host)

      Signal.trap('INT') do
        puts "Stopping nicely..."
        dispatcher.stop
        puts "Bye."
        exit
      end

      dispatcher.run do |input|
        output = []
        input.each_slice(region.input_size) do |slice|
          data = Array.new(region.input_size) { 0b0 }

          slice.each_with_index { |byte, i|
            8.times { |n| data[i] = byte[n] }
          } unless slice.empty?

          region.tick(data)
          output << region.output
        end
        output
      end
    end
    module_function :node
  end
end
