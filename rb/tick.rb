# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
game = Game.current
game.tick

ImUI.draw_text(text: 'Test', pos: Vector.new(300, 200), size: 40, color: Color.pink)
