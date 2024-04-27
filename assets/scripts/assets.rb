# frozen_string_literal: true

class Fonts
  def self.kenney_future
    @kenney_future ||= AssetSystem.add_font('assets/fonts/Kenney Future.ttf')
  end
end
