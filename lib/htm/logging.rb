module HTM
  module Logging
    def out(message)
      $stdout.puts preamble + message
    end
  
    def err(message)
      $stderr.puts preamble + message
    end
  
    #def verbose(message)
    #  return unless Config.verbose
    #  out(message)
    #end
  
    def preamble
      "[#{self.class.name}] "
    end
  end
end