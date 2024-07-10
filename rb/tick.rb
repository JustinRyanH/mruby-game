# frozen_string_literal: true

# require 'assets/scripts/setup'
# require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick
#

require 'assets/scripts/assets'

class RevealGame
  def tick
    setup unless ready?
    screen = FrameInput.screen
    mouse_pos = FrameInput.mouse_pos

    text_pos = Vector.new(screen.size.x * 0.5, screen.size.y - 72)
    Draw.text(text: 'Sonar Test', pos: text_pos, halign: :center, size: 16)
    @dynamic_sprite.pos = mouse_pos

    return unless FrameInput.mouse_just_pressed?(:left)

    Echolocation.reveal(
      pos: FrameInput.mouse_pos,
      rotation: 0,
      texture: Textures.copter,
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
      texture: Textures.copter,
      pos: world_pos,
      size: world_size,
      type: :dynamic,
      z_offset: 1.1,
      tint: Color.purple,
    )

    background_sprites << Sprite.create(
      texture: Textures.platform_middle,
      pos: world_pos,
      size: world_size,
      type: :static,
    )
    background_sprites << Sprite.create(
      texture: Textures.platform_middle_right,
      pos: world_pos + Vector.new(16, 0),
      size: world_size,
      type: :static,
    )
    background_sprites << Sprite.create(
      texture: Textures.platform_middle_left,
      pos: world_pos - Vector.new(16, 0),
      size: world_size,
      type: :static,
    )
  end

  def background_sprites
    @background_sprites = []
  end
end

$game ||= RevealGame.new
$game.tick
