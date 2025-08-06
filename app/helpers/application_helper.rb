module ApplicationHelper
  def parse_time_from_session(time_value)
    return nil if time_value.nil?
    
    if time_value.is_a?(String)
      Time.zone.parse(time_value)
    elsif time_value.is_a?(ActiveSupport::TimeWithZone) || time_value.is_a?(Time) || time_value.is_a?(DateTime)
      time_value
    else
      # Fallback para otros tipos
      Time.zone.parse(time_value.to_s)
    end
  rescue => e
    Rails.logger.error "Error parsing time from session: #{e.message}"
    Time.current
  end
end
