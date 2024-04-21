# frozen_string_literal: true

class Log
  # @param [String] msg
  def self.info(msg); end
  # @param [String] msg
  def self.error(msg); end
  # @param [String] msg
  def self.fatal(msg); end
  # @param [String] msg
  def self.warning(msg); end
end

class FrameInput
  # @return [Float]
  def self.delta_time; end
end

class Vector
  # @param [Float]
  # @return [Float]
  attr_accessor :x
  # @param [Float]
  # @return [Float]
  attr_accessor :y


  # Create a Zero Vector
  #
  # @return [Vector]
  def self.zero; end

  # @param [Float] x
  # @param [Float] y
  def initialize(x, y); end

  # Adds two vectors together
  #
  # @param [Vector] other
  # @return [Vector] new_value
  def +(other); end

  # Scales a Vector
  #
  # @param [Float] scalar
  # @return [Vector]
  def *(other); end
end
