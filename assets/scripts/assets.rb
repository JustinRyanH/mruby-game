# frozen_string_literal: true

class Fonts
  def self.kenney_future
    @kenney_future ||= AssetSystem.add_font('assets/fonts/Kenney Future.ttf')
  end
end

class Sounds
  def self.thruster
    @thruster ||= AssetSystem.load_sound('assets/sounds/kenney_thruster.ogg')
  end

  def self.explosion
    @explosion ||= AssetSystem.load_sound('assets/sounds/kenney_explosion.ogg')
  end

  def self.laser
    @laser ||= AssetSystem.load_sound('assets/sounds/kenney_laser.ogg')
  end
end

class Textures
  def self.bg0
    @bg0 ||= AssetSystem.load_texture('assets/textures/BG-0.png')
  end

  def self.bg1
    @bg1 ||= AssetSystem.load_texture('assets/textures/BG-1.png')
  end

  def self.bg2
    @bg2 ||= AssetSystem.load_texture('assets/textures/BG-2.png')
  end

  def self.copter
    @copter ||= AssetSystem.load_texture('assets/textures/copter_1.png')
  end

  def self.copter2
    @copter2 ||= AssetSystem.load_texture('assets/textures/copter_2.png')
  end

  def self.copter3
    @copter3 ||= AssetSystem.load_texture('assets/textures/copter_3.png')
  end

  def self.square
    @square ||= AssetSystem.load_texture('assets/textures/square.png')
  end

  def self.platform_top_middle
    @platform_top_middle ||= AssetSystem.load_texture('assets/textures/platform_um.png')
  end

  def self.platform_top_left
    @platform_top_left ||= AssetSystem.load_texture('assets/textures/platform_ulc.png')
  end

  def self.platform_top_right
    @platform_top_right ||= AssetSystem.load_texture('assets/textures/platform_urc.png')
  end

  def self.platform_middle
    @platform_middle ||= AssetSystem.load_texture('assets/textures/platform_m.png')
  end

  def self.platform_middle_left
    @platform_middle_left ||= AssetSystem.load_texture('assets/textures/platform_lm.png')
  end

  def self.platform_middle_right
    @platform_middle_right ||= AssetSystem.load_texture('assets/textures/platform_rm.png')
  end

  def self.platform_lower_middle
    @platform_lower_middle ||= AssetSystem.load_texture('assets/textures/platform_bm.png')
  end

  def self.platform_lower_left
    @platform_lower_left ||= AssetSystem.load_texture('assets/textures/platform_blc.png')
  end

  def self.platform_lower_right
    @platform_lower_right ||= AssetSystem.load_texture('assets/textures/platform_brc.png')
  end
end

SQUARE_MAP = {
  middle_middle: Textures.platform_middle,
  middle_left: Textures.platform_middle_left,
  middle_right: Textures.platform_middle_right,
  upper_left: Textures.platform_top_left,
  upper_middle: Textures.platform_top_middle,
  upper_right: Textures.platform_top_right,
  lower_left: Textures.platform_lower_left,
  lower_middle: Textures.platform_lower_middle,
  lower_right: Textures.platform_lower_right
}.freeze
