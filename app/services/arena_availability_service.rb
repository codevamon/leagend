class ArenaAvailabilityService
  def initialize(arena, date:, slot_minutes: 60)
    @arena = arena
    @date  = date
    @slot  = slot_minutes
  end

  def call
    window = business_window_for(@date)
    return [] if window.nil?

    blocks = closure_blocks_for(@date) + reservation_blocks_for(@date)
    slots_from(window).reject { |slot| blocked?(slot, blocks) }
  end

  private

  def business_window_for(date)
    wday = date.wday # 0..6
    bh = @arena.business_hours.find_by(weekday: wday)
    return nil if bh.nil? || bh.closed?

    from = Time.zone.local(date.year, date.month, date.day, bh.opens_at.hour, bh.opens_at.min)
    to   = Time.zone.local(date.year, date.month, date.day, bh.closes_at.hour, bh.closes_at.min)
    (from...to)
  end

  def closure_blocks_for(date)
    day_start = date.beginning_of_day
    day_end   = date.end_of_day
    @arena.closures.where("starts_at < ? AND ends_at > ?", day_end, day_start)
          .pluck(:starts_at, :ends_at).map { |s,e| (s...e) }
  end

  def reservation_blocks_for(date)
    day_start = date.beginning_of_day
    day_end   = date.end_of_day
    @arena.reservations.where(status: %w[held reserved paid])
          .where("starts_at < ? AND ends_at > ?", day_end, day_start)
          .pluck(:starts_at, :ends_at).map { |s,e| (s...e) }
  end

  def slots_from(window)
    slots = []
    t = window.begin
    while t + @slot.minutes <= window.end
      slots << (t...(t + @slot.minutes))
      t += @slot.minutes
    end
    slots.map(&:begin) # devolver inicios
  end

  def blocked?(slot_start, blocks)
    slot_end = slot_start + @slot.minutes
    blocks.any? { |b| slot_start < b.end && b.begin < slot_end }
  end
end
