class ArenaVerificationService
  def submit(arena:, user:, method:, payload:, documents: [])
    v = ArenaVerification.create!(
      arena_id: arena.id, submitted_by_id: user.id,
      status: "submitted", payout_method: method, payout_payload: payload
    )
    documents.each { |doc| v.documents.attach(doc) }
    arena.update!(status: "pending_review")
    v
  end

  def approve(verification:, admin_user:)
    verification.update!(status: "approved")
    verification.arena.update!(status: "verified")
  end

  def reject(verification:, reason:)
    verification.update!(status: "rejected", rejection_reason: reason)
    verification.arena.update!(status: "unverified")
  end
end
