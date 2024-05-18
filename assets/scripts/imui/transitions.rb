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

  def initialize(origin, target, time: nil, ease: :linear)
    @origin = origin
    @target = target
    @time = time
    @timer = time.nil? ? nil : Timer.new(time)
    @ease = ease
  end

  def target=(new_target)
    @target = new_target
    return if timer.nil?

    @origin = current_pos

    timer.reset(@time)
  end

  def update
    return target if timer.nil?

    timer.tick
    current_pos
  end

  def finished?
    return true if timer.nil?

    timer.finished?
  end

  private

  def current_pos
    origin.lerp(target, timer.percentage.ease(ease))
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
  define_attr :time, default: :linear

  def build_transition(origin, target)
    LerpTransition.new(origin, target, time:, ease:)
  end
end

class Transitions
  include DefinedAttribute

  define_attr :pos, default: DefineJumpTransition.new
end
