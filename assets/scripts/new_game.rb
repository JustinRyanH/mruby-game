# frozen_string_literal: true

GRAVITY = 150

class SpringCamera
  attr_reader :camera, :velocity, :spring

  attr_accessor :pos

  def self.create(
    pos: Vector.zero,
    offset: Vector.new(*FrameInput.screen_size),
    spring: Spring.new(10, 1)
  )
    camera = Camera.create(pos:, offset:)
    new(camera:, pos:, spring:)
  end

  def initialize(camera:, pos:, spring:)
    @camera = camera
    @pos = pos
    @velocity = Vector.zero
    @spring = spring
  end

  def tick
    camera.pos, @velocity = spring.motion(camera.pos, velocity, @pos)
  end
end

class LoopingBackground
  attr_reader :size, :left, :middle, :right

  def initialize(texture:, parallax:, z_offset:)
    @size = Vector.new(1280, 720) * 1.2
    bg_pos = Vector.new(size.x, 0)

    @left = Sprite.create(pos: bg_pos * -1, size:, texture:, z_offset:, parallax:)
    @middle = Sprite.create(pos: Vector.zero, size:, texture:, z_offset:, parallax:)
    @right = Sprite.create(pos: bg_pos, size:, texture:, z_offset:, parallax:)
  end

  def tick
    camera_pos = Camera.current.pos
    move_all_right if @right.parallax_bounds.inside?(camera_pos)
    move_all_left if @left.parallax_bounds.inside?(camera_pos)
  end

  def move_all_left
    offset = Vector.new(size.x, 0)
    @left.pos -= offset
    @middle.pos -= offset
    @right.pos -= offset
  end

  def move_all_right
    offset = Vector.new(size.x, 0)
    @left.pos += offset
    @middle.pos += offset
    @right.pos += offset
  end
end

class EchoBat < GameObject
  attr_reader :base_speed, :velocity

  def self.create(pos:, base_speed:)
    size = Vector.new(64, 64)

    sprite = Sprite.create(pos:, size:, texture: Textures.copter, tint: Color.black)
    collider = Collider.create(pos:, size:)

    new(collider:, sprite:, base_speed:)
  end

  def initialize(base_speed:, **)
    super(**)
    @base_speed = base_speed
    @velocity = Vector.new(base_speed, GRAVITY)
  end

  def tick
    super
    @velocity.x = base_speed
    @velocity.y += GRAVITY * dt
    if FrameInput.key_down?(:a)
      @velocity.x = base_speed * 0.2
      @velocity.y = GRAVITY * 1.5
    end
    @velocity.y = if FrameInput.key_down?(:s)
                    @velocity.y += 10
                    @velocity.y.clamp(-200, GRAVITY * 4)
                  else
                    @velocity.y.clamp(-200, GRAVITY)
                  end

    @velocity.y -= 100 if FrameInput.key_just_pressed?(:space)

    self.pos += @velocity * FrameInput.delta_time
  end
end

class TestGame
  attr_reader :backgrounds

  def initialize
    @started = false
  end

  def tick
    setup unless @started
    @player.tick

    @camera.spring.frequency = 6
    @camera.spring.damping = 0.8
    @camera.pos.x = @player.pos.x
    @camera.tick
    backgrounds.each(&:tick)
  end

  def setup
    @started = true

    create_camera
    create_player
    @backgrounds = [
      LoopingBackground.new(texture: Textures.bg0, z_offset: -1, parallax: 0.9),
      LoopingBackground.new(texture: Textures.bg1, z_offset: -0.95, parallax: 0.85),
    ]
  end

  private

  def create_camera
    offset = FrameInput.screen.size
    offset.x *= 0.25
    offset.y *= 0.5
    @camera = SpringCamera.create(pos: Vector.zero, offset:)
    Camera.current = @camera.camera
  end

  def create_player
    pos = Vector.zero
    @player = EchoBat.create(pos:, base_speed: 300)
  end
end
