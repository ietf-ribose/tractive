require 'singleton'

module Tractive
  class GracefulQuit
    include Singleton

    attr_accessor :breaker

    def initialize
      self.breaker = false
    end

    def self.enable
      trap('INT') {
        yield if block_given?
        self.instance.breaker = true
      }
    end

    def self.check(message = "Quitting")
      if self.instance.breaker
        yield if block_given?
        $log.info message
        exit
      end
    end

  end
end