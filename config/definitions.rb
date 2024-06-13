# frozen_string_literal: true

class Screen
  # Returns the size of the screen
  #
  # @return [Vector]
  def size
  end

  # Returns Position of the screen.
  # Generaly Vector{ x: 0, y: 0 }
  #
  # @return [Vector]
  def pos
  end

  # returns where on the Screen Rect the pos is located
  # Generaly Vector{ x: 0, y: 0 }
  #
  # @return [Vector]
  def anchor_percentage
  end
end

class Log
  # @param [String] msg
  def self.info(msg)
  end

  # @param [String] msg
  def self.error(msg)
  end

  # @param [String] msg
  def self.fatal(msg)
  end

  # @param [String] msg
  def self.warning(msg)
  end
end

class FrameInput
  # How long since the last frame
  #
  # @return [Float]
  def self.delta_time
  end

  # What # the frame we are on
  #
  # @return [Integer]
  def self.id
  end

  # Whether the key is down on this frame
  #
  # @return [Boolean]
  def self.key_down?(key)
  end

  # Whether the key is down this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.key_just_pressed?(key)
  end

  # Whether the key is up this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.key_was_down?(key)
  end

  # Get Screen Abstraction
  #
  # @return [Screen]
  def self.screen
  end

  # Get the width and height of the curent frame
  #
  # @return [Array(Number, Number)]
  def self.screen_size
  end

  # Gets the current mouse position
  #
  # @return [Vector]
  def self.mouse_pos
  end

  # Whether the mouse button is down on this frame
  #
  # @return [Boolean]
  def self.mouse_down?(key)
  end

  # Whether the mouse button is down this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.mouse_just_pressed?(key)
  end

  # Whether the mouse button is up this frame,
  # but not the last
  #
  # @return [Boolean]
  def self.mouse_was_down?(key)
  end

  # Gets a random float betwen the given range,
  # it will raise if you pass in an inclusive range
  #
  # @param [Range] low..high
  # @return [Float]
  def self.random_float(rng)
  end

  # Gets a random Integer betwen the given range,
  #
  # @param [Range] low..high
  # @return [Float]
  def self.random_int(rng)
  end
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
  def self.zero
  end

  # @param [Float] x
  # @param [Float] y
  def initialize(x, y)
  end

  # Adds two vectors together
  #
  # @param [Vector] other
  # @return [Vector] new_value
  def +(other)
  end

  # Scales a Vector
  #
  # @param [Float] scalar
  # @return [Vector]
  def *(other)
  end
end

class Collider
  # Create a Collider
  #
  # @param [Vector] pos
  # @param [Vector] size
  def self.create(pos:, size:)
  end

  # Destroys the Collider, becomes invalid
  def destroy
  end

  # Returns the ID of the Collider
  #
  # @return [Integer] id
  def id
  end

  # Returns the Collider is valid
  #
  # @return [Boolean]
  def valid?
  end

  # Returns Position of the collider
  #
  # @return [Vector]
  def pos
  end

  # Sets the position of the vector
  #
  # @param [Vector] value
  def pos=(value)
  end

  # Gets the size
  #
  # @return [Vector]
  def sizeg
  end

  # Gets the other elements the collider is colliding with
  #
  # @return [Set<Collider>]
  def collisions
  end
end

module Draw
  # Draws a Rectangle
  #
  # @param [Vector] pos
  # @param [Vector] size
  # @param [Vector] anchor_percetnage - 0..1 values inside the
  # @param [Symbol] mode `:solid` or `:outline`
  # @param [Color] color
  def self.rect(pos:, size:, anchor_percetnage: Vector.zero, mode: solid, color: Color.red)
  end

  # Draws Text
  #
  # @param [String] text
  # @param [Vector] pos
  # @param [Vector] size
  # @param [Color] color
  # @param [Font] font
  # @param [Symbol] halign `:left`, `:right`, or `:ecente`
  def self.text(text:, pos:, font:, size: color, halign: :left)
  end

  # Draws a Texture to the Screen
  #
  # @param [Texture] texture
  # @param [Vector] pos
  # @param [Vector] size
  # @param [Vector] offset_percentage
  # @param [Float] rotation
  # @param [Color] tint
  def self.texture(
    texture:,
    pos:,
    size: nil,
    offset_percentage: Vector.new(0.5, 0.5),
    rotation: 0.0,
    tint: Color.white
  ); end

  # Measure out the Text
  #
  # @param [String] text
  # @param [Vector] size
  # @param [Font] font
  # @return [Vector]
  def self.measure_text
  end

  # Draws a line from start to finish
  #
  # @param [Vector] start
  # @param [Vector] end
  # @param [Float] thickness
  # @param [Color] color
  def self.line(start:, end:, thickness: 2, color: Color.red)
  end
end

class Engine
  # Takes a ruby string and gives you a hash
  #
  # @param [String] str
  # @return [Integer]
  def self.hash_str(str)
  end
end
