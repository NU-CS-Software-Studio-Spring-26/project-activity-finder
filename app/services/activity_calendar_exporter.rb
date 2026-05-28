class ActivityCalendarExporter
  def initialize(activity)
    @activity = activity
  end

  def render
    calendar = Icalendar::Calendar.new
    calendar.append_custom_property("X-WR-CALNAME", "Activity Finder")

    event = Icalendar::Event.new
    event.uid = "activity-#{@activity.id}@activity-finder"
    event.summary = @activity.title.to_s
    event.description = @activity.description.to_s
    event.location = location_value
    event.dtstart = Icalendar::Values::Date.new(@activity.event_date)
    event.dtend = Icalendar::Values::Date.new(@activity.event_date + 1.day)
    event.created = @activity.created_at&.utc || Time.current.utc
    event.last_modified = @activity.updated_at&.utc || Time.current.utc
    event.organizer = "mailto:#{@activity.user.email}" if @activity.user&.email.present?

    calendar.add_event(event)
    calendar.publish
    calendar.to_ical
  end

  private

  def location_value
    parts = [@activity.location, @activity.city].map { |part| part.to_s.strip.presence }.compact
    parts.join(", ").presence || "TBD"
  end
end
