class ArenaReservationService
  def hold(arena:, user:, starts_at:, ends_at:)
    Reservation.create!(
      reservable: arena,
      status: "held",
      starts_at: starts_at,
      ends_at: ends_at,
      payer_id: user.id,
      receiver_id: arena.owner.user_id,
      currency: arena.currency || "COP",
      amount_cents: amount_for(arena, starts_at, ends_at)
    )
  end

  def reserve(arena:, user:, starts_at:, ends_at:)
    raise "Arena no verificada" unless arena.verified?
    Reservation.create!(
      reservable: arena,
      status: "reserved",
      starts_at: starts_at,
      ends_at: ends_at,
      payer_id: user.id,
      receiver_id: arena.owner.user_id,
      currency: arena.currency || "COP",
      amount_cents: amount_for(arena, starts_at, ends_at)
    )
  end

  def mark_paid(reservation:, provider:, payment_ref:)
    reservation.update!(status: "paid", payment_provider: provider, payment_ref: payment_ref)
  end

  def cancel(reservation:)
    reservation.update!(status: "canceled")
  end

  private
  def amount_for(arena, from, to)
    hours = ((to - from) / 3600.0).ceil
    ((arena.price_per_hour || 0) * 100).to_i * hours
  end
end
