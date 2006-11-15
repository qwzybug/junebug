
module Junebug
  module Config
    extend self
    
    def rootdir
      return File.dirname(__FILE__) + "/../../"
    end
    
    def script
      return File.dirname(__FILE__) + "/../junebug.rb"
    end
    
  end
end