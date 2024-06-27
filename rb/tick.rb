# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick

# require 'assets/scripts/setup'
# require 'assets/scripts/new_game'
#
require 'assets/scripts/assets'
# $new_game ||= TestGame.new
# $new_game.tick
ATLAS_WIDTH = 1024

class TexturePacking
  def tick
    setup unless ready?
    center = FrameInput.screen.size * 0.5
    @atlas.draw(center)
    Draw.rect(pos: center, size: Vector.new(ATLAS_WIDTH, 128), mode: :outline)
  end

  def setup
    @ready = true
    texture_paths = [
      'copter_1.png',
      'copter_2.png',
      'copter_3.png',
    ].map { |path| "assets/textures/#{path}" }
    @atlas = AssetSystem.pack_textures(
      name: 'atlas_example',
      paths: texture_paths,
      width: ATLAS_WIDTH,
      height: 128,
    )

    Sprite.create(pos: Vector.new(300, 200), size: Vector.new(32, 32), texture: Textures.copter)
    Sprite.create(pos: Vector.new(400, 200), size: Vector.new(32, 32), texture: Textures.copter2)
    Sprite.create(pos: Vector.new(450, 200), size: Vector.new(32, 32), texture: Textures.copter3)
    Sprite.create(pos: Vector.new(500, 200), size: Vector.new(32, 32), texture: Textures.copter)
  end

  def ready?
    @ready || false
  end
end

$packing ||= TexturePacking.new
$packing.tick
