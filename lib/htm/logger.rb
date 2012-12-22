module HTM
  module Logger
    module_function

    # Send a debug message
    def debug(string)
      HTM.logger.debug(string) if HTM.logger
    end

    # Send a info message
    def info(string)
      HTM.logger.info(string) if HTM.logger
    end

    # Send a warning message
    def warn(string)
      HTM.logger.warn(string) if HTM.logger
    end

    # Send an error message
    def error(string)
      HTM.logger.error(string) if HTM.logger
    end
  end
end
