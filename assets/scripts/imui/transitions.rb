# frozen_string_literal: true

require 'assets/scripts/common'

class JumpTransition
  attr_reader :origin, :target

  def initialize(origin, target)
    @origin = origin
    @target = target
  end

  def update
    target
  end

  def finished?
    true
  end
end

class LerpTransition
  # @param [Timer] timer
  attr_reader :origin, :target

  def initialize(origin, target, time:, ease: :linear)
    @origin = origin
    @target = target

    @time = time
    @timer = Timer.new(time)
    @ease = ease
  end

  def target=(new_target)
    @origin = current_pos
    @target = new_target

    timer.reset
  end

  def update
    timer.tick
    current_pos
  end

  def finished?
    timer.finished?
  end

  private

  attr_reader :ease, :timer, :time

  def current_pos
    origin.lerp(target, timer.percentage.ease(ease))
  end
end

class DistanceTransition
  # @param [Timer] timer
  attr_reader :origin, :target

  def initialize(origin, target, pixels_per_second: 20, ease: :linear)
    @origin = origin
    @target = target
    @pixels_per_second = pixels_per_second
    @length = (origin - target).length
    @ease = ease
    @stopwatch = Stopwatch.new
  end

  def target=(new_target)
    @origin = current_pos
    @target = new_target
    @length = (origin - target).length

    stopwatch.reset
  end

  def update
    stopwatch.tick
    current_pos
  end

  def finished?
    percentage >= 1
  end

  private

  attr_reader :stopwatch, :length, :pixels_per_second, :ease

  def current_pos
    @origin.lerp(@target, percentage.ease(ease))
  end

  def percentage
    ((stopwatch.time * pixels_per_second) / length).clamp(0, 1)
  end
end

class DefineJumpTransition
  include DefinedAttribute

  def build_transition(origin, target)
    JumpTransition.new(origin, target)
  end
end

class DefineLerpTransition
  include DefinedAttribute

  # @param [Float] time
  define_attr :time, default: 0.2
  # @param [Symbol] ease
  define_attr :ease, default: :linear

  def build_transition(origin, target)
    LerpTransition.new(origin, target, time:, ease:)
  end
end

class DefineDistanceTransition
  include DefinedAttribute

  # @param [Float] time
  define_attr :pixels_per_second, default: 20
  # @param [Symbol] ease
  define_attr :ease, default: :linear

  def build_transition(origin, target)
    DistanceTransition.new(origin, target, pixels_per_second:, ease:)
  end
end

class Transitions
  include DefinedAttribute

  define_attr :pos, default: DefineJumpTransition.new
end
