# frozen_string_literal: true

# require 'assets/scripts/setup'
# require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick

require 'assets/scripts/common'
require 'assets/scripts/engine_override'
require 'assets/scripts/assets'

class Block
  include Bounds

  attr_reader :velocity, :game, :size

  def initialize(game, pos:, size:, velocity: Vector.new(1, 0))
    @game = game
    @size = size
    @sprite = Sprite.create(
      texture: Textures.square,
      pos:,
      size:,
      type: :dynamic,
      tint: Color.crushed_cashew,
    )
    @source = pos
    @collider = Collider.create(pos:, size:)
    @velocity = velocity
  end

  def update
    self.pos += velocity
    collisions = @collider.collisions
    if collisions.any?
      event = collisions.first
      game.collide_entity(self, event)
      return
    end

    game.destroy_entity(self) if distance_travelled > 200
  end

  def pos
    @sprite.pos
  end

  def pos=(value)
    @sprite.pos = value
    @collider.pos = value
  end

  def destroy
    @sprite.destroy
    @collider.destroy
  end

  def distance_travelled
    (@source - pos).length
  end
end

class Terrain
  def initialize(pos:)
    size = Vector.new(16, 16)
    @sprite = Sprite.create(
      texture: Textures.square,
      pos:,
      size:,
      type: :static,
      tint: Color.affinity,
    )
    @collider = Collider.create(pos:, size:)
  end
end

class RevealGame
  attr_reader :mouse_pos

  def tick
    setup unless ready?
    screen = FrameInput.screen
    @mouse_pos = FrameInput.mouse_pos.floor!

    text_pos = Vector.new(screen.size.x * 0.5, screen.size.y - 72)
    Draw.text(text: 'Sonar Test', pos: text_pos, halign: :center, size: 16)
    @dynamic_sprite.pos = mouse_pos

    spawn_echo if FrameInput.mouse_just_pressed?(:left)

    entities.each(&:update)
  end

  private

  def spawn_echo
    sections = 40
    scale = 10
    sections.times do |v|
      distance_travelled = v.to_f / sections
      x_pos = Math.cos(Math.tau * distance_travelled)
      y_pos = Math.sin(Math.tau * distance_travelled)

      unit_pos = Vector.new(x_pos, y_pos)
      pos = (unit_pos * scale) + mouse_pos
      entities << Block.new(self, pos:, size: Vector.all(1), velocity: unit_pos)
    end
  end

  def ready?
    @ready || false
  end

  def setup
    @ready = true
    Engine.background_color = Color.crow_black_blue
    screen = FrameInput.screen
    world_pos = screen.size * 0.5

    @dynamic_sprite = Sprite.create(
      texture: Textures.square,
      pos: world_pos,
      size: Vector.new(2, 2),
      type: :dynamic,
      z_offset: 1.1,
      tint: Color.purple,
    )
    background_sprites << Terrain.new(pos: world_pos)
    background_sprites << Terrain.new(pos: world_pos - Vector.new(16, 0))
    background_sprites << Terrain.new(pos: world_pos + Vector.new(16, 0))
  end

  def collide_entity(entity, event)
    normal = event.normal
    rotation = normal.angle.to_degrees
    pos = (entity.pos - (normal * event.depth.round))
    Echolocation.reveal(pos:, rotation:, texture: Textures.echo)
    destroy_entity(entity)
  end

  def destroy_entity(entity)
    entities.reject! { |ent| ent == entity }
    entity.destroy
  end

  def background_sprites
    @background_sprites ||= []
  end

  def entities
    @entities ||= []
  end
end

$game ||= RevealGame.new
$game.tick
