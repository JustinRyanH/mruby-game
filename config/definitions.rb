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
  # How long since the last frame
  #
  # @return [Float]
  def self.delta_time; end

  # What # the frame we are on
  #
  # @return [Integer]
  def self.id; end

  # Whether the key is down on this frame
  #
  # @return [Boolean]
  def self.key_down?(key); end

  # Whether the key is down this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.key_just_pressed?(key); end

  # Whether the key is up this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.key_was_down?(key); end

  # Get the width and height of the curent frame
  #
  # @return [Array(Number, Number)]
  def self.screen_size; end

  # Gets a random float betwen the given range,
  # it will raise if you pass in an inclusive range
  #
  # @param [Range] low..high
  # @return [Float]
  def self.random_float(rng); end

  # Gets a random Integer betwen the given range,
  #
  # @param [Range] low..high
  # @return [Float]
  def self.random_int(rng); end
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

module ImUI
  # Draws a Rectangle
  #
  # @param [Vector] pos
  # @param [Vector] size
  # @param [Vector] anchor_percetnage - 0..1 values inside the
  # @param [Symbol] mode `:solid` or `:outline`
  def self.draw_rect(pos:, size:, anchor_percetnage: Vector.zero, mode: solid); end
end
