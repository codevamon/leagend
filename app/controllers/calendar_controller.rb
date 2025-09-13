class CalendarController < ApplicationController
  before_action :authenticate_user!

  def events
    @reservations = Reservation.all
    @availabilities = Availability.all

    respond_to do |format|
      format.json { render "shared/calendar_events" }
    end
  end
end
