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
  attr_reader :pos, :collider

  def initialize(pos:)
    @pos = pos
    @bounds = Rectangle.zero
    @collider = nil
    @sprites = []
  end

  def replace(builder)
    destroy

    builder.pos = pos

    @bounds = builder.bounds

    @collider = Collider.create(pos: bounds.pos, size: bounds.size)
    @sprites = builder.build
  end

  def pos=(new_pos)
    new = new_pos - @pos
    @sprites.each { |spr| spr.pos += new }
    @pos = new_pos
    @collider.pos = new_pos
  end

  def destroy
    @sprites.each(&:destroy)
    @collider&.destroy
    @collider = nil
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

    @obs.pos -= Vector.new(1, 0) if FrameInput.key_down?(:a)
    @obs.pos += Vector.new(1, 0) if FrameInput.key_down?(:d)

    Engine.debug = !Engine.debug? if FrameInput.key_was_down?(:p)
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
