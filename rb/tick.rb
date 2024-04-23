# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
game = Game.current
game.tick

ImUI.draw_text(text: 'Hello world', pos: Vector.new(400, 200), size: 24, font: Fonts.kenney_future)
