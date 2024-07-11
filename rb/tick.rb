# frozen_string_literal: true

# require 'assets/scripts/setup'
# require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick

require 'assets/scripts/assets'

class Terrain
  def initialize(pos:, side:)
    @sprite = Sprite.create(
      texture: Textures.square,
      pos:,
      size: Vector.new(16, 16),
      type: :static,
      tint: Color.affinity,
    )
  end
end

class RevealGame
  def tick
    setup unless ready?
    screen = FrameInput.screen
    mouse_pos = FrameInput.mouse_pos.floor!

    text_pos = Vector.new(screen.size.x * 0.5, screen.size.y - 72)
    Draw.text(text: 'Sonar Test', pos: text_pos, halign: :center, size: 16)
    @dynamic_sprite.pos = mouse_pos

    return unless FrameInput.mouse_just_pressed?(:left)

    Echolocation.reveal(
      pos: mouse_pos,
      rotation: 0,
      texture: Textures.echo,
    )
  end

  private

  def ready?
    @ready || false
  end

  def setup
    @ready = true
    screen = FrameInput.screen
    world_size = Vector.new(16, 16)
    world_pos = screen.size * 0.5

    @dynamic_sprite = Sprite.create(
      texture: Textures.echo,
      pos: world_pos,
      size: Vector.new(16, 2),
      type: :dynamic,
      z_offset: 1.1,
      tint: Color.purple,
      anchor: Vector.zero,
    )
    Terrain.new(pos: world_pos, side: :middle)
    Terrain.new(pos: world_pos - Vector.new(16, 0), side: :left)
    Terrain.new(pos: world_pos + Vector.new(16, 0), side: :right)
  end

  def background_sprites
    @background_sprites = []
  end
end

$game ||= RevealGame.new
$game.tick
