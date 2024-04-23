# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
# game = Game.current
# game.tick
width, height = FrameInput.screen_size
ImUI.draw_text(
  text: 'Game Over',
  pos: Vector.new(width / 2, height / 2),
  size: 42,
  halign: :center,
  font: Fonts.kenney_future
)
