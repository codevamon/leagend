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

  def callup_status_badge(player, team, duel)
    existing_callup = team.callups.find_by(user: player, duel: duel)
    return nil unless existing_callup
    
    case existing_callup.status
    when 'pending'
      content_tag :span, class: "badge bg-warning" do
        content_tag(:i, "", class: "fas fa-clock me-1") + "Pendiente"
      end
    when 'accepted'
      content_tag :span, class: "badge bg-success" do
        content_tag(:i, "", class: "fas fa-check me-1") + "Confirmado"
      end
    when 'rejected'
      content_tag :span, class: "badge bg-danger" do
        content_tag(:i, "", class: "fas fa-times me-1") + "Rechazado"
      end
    end
  end
end
