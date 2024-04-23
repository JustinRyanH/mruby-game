# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
game = Game.current
game.tick

y = (Math.sin(FrameInput.id * 0.01) + 1) * 0.5
x = (Math.cos(FrameInput.id * 0.01) + 1) * 0.5

ImUI.draw_rect(
  pos: Vector.new(400, 100),
  size: Vector.new(75, 100),
  anchor_percentage: Vector.new(x, y),
  mode: :outline
)
