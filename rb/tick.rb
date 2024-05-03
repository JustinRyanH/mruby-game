# frozen_string_literal: true

require 'assets/scripts/setup'
require 'assets/scripts/tilemap'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
# This
class StaticObject
  attr_reader :pos, :bounds

  def initialize(pos:)
    @pos = pos
    @bounds = Rectangle.zero
    @sprites = []
  end

  def replace(builder)
    destroy

    builder.pos = pos

    @bounds = builder.bounds
    @sprites = builder.build
  end

  def pos=(new_pos)
    new = new_pos - @pos
    @sprites.each do |spr|
      puts spr.inspect
      spr.pos += new
    end
    @pos = new
  end

  def destroy
    @sprites.each(&:destroy)
  end
end

class Demo
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    width, height = FrameInput.screen_size
    Draw.line(start: Vector.new(width / 2, 0), end: Vector.new(width / 2, height))
    Draw.line(start: Vector.new(0, height / 2), end: Vector.new(width, height / 2))

    @obs.pos -= Vector.new(1, 0) * FrameInput.delta_time if FrameInput.key_down?(:a)
    return unless FrameInput.key_down?(:d)

    @obs.pos += Vector.new(1, 0) * FrameInput.delta_time
  end

  def setup
    rebuild_map
    @ready = true
  end

  def ready?
    @ready
  end

  private

  def rebuild_map
    width, height = FrameInput.screen_size
    pos = Vector.new(width / 2, height / 2)
    @width ||= 5
    @height ||= 5

    @obs = StaticObject.new(pos:)
    tmr = TileMapBuilder.new(width: @width, height: @height, tint: Color.affinity)
    @obs.replace(tmr)
  end
end

$demo ||= Demo.new
$demo.tick
