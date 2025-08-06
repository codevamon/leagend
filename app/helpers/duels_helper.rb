module DuelsHelper
  def captain_callup_status(duel, team)
    callup = duel.callups.find_by(user: team.captain, teamable: team)
    if callup.present? && callup.accepted?
      'confirmed'
    elsif callup.present? && callup.pending?
      'pending'
    else
      'not_called'
    end
  end

  def captain_callup_badge_class(status)
    case status
    when 'confirmed'
      'bg-success'
    when 'pending'
      'bg-warning'
    else
      'bg-secondary'
    end
  end

  def captain_callup_icon(status)
    case status
    when 'confirmed'
      'fas fa-check'
    when 'pending'
      'fas fa-clock'
    else
      'fas fa-user-plus'
    end
  end
end
