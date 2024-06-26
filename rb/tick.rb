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
# $new_game ||= TestGame.new
# $new_game.tick

class TexturePacking
  def tick
    setup unless ready?
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
      width: 1024,
      height: 1024,
    )
    puts "Atlas Size: #{@atlas.size.inspect}"
  end

  def ready?
    @ready || false
  end
end

$packing ||= TexturePacking.new
$packing.tick
