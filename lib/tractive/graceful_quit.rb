# frozen_string_literal: true

require "singleton"

module Tractive
  class GracefulQuit
    include Singleton

    attr_accessor :breaker

    def initialize
      self.breaker = false
    end

    def self.enable
      trap("INT") do
        yield if block_given?
        instance.breaker = true
      end
    end

    def self.check(message = "Quitting")
      if instance.breaker
        yield if block_given?
        $logger.info message
        exit
      end
    end
  end
end
