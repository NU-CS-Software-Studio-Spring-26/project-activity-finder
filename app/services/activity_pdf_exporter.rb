class ActivityPdfExporter
  def initialize(activity)
    @activity = activity
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
      pdf.text "Activity Report", size: 22, style: :bold
      pdf.move_down 12

      pdf.text "Title: #{@activity.title}"
      pdf.text "Date: #{formatted_date}"
      pdf.text "City: #{safe_value(@activity.city)}"
      pdf.text "Location: #{safe_value(@activity.location)}"
      pdf.text "Category: #{safe_value(@activity.category)}"
      pdf.text "Host: #{safe_value(@activity.user&.name)}"
      pdf.move_down 8

      pdf.text "Description", style: :bold
      pdf.text safe_value(@activity.description)
      pdf.move_down 12

      pdf.text "Attendance", size: 16, style: :bold
      pdf.text attendance_summary
      pdf.move_down 8

      attendees = @activity.attendees.order(:name)
      if attendees.any?
        rows = [ [ "#", "Name", "Email" ] ]
        attendees.each_with_index do |attendee, index|
          rows << [ index + 1, attendee.name.to_s, attendee.email.to_s ]
        end

        pdf.table(rows, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "EEEEEE"
          columns(0).width = 35
          columns(1).width = 180
        end
      else
        pdf.text "No attendees yet."
      end

      pdf.number_pages "Generated on #{Time.current.strftime('%B %d, %Y %H:%M')} - Page <page>/<total>",
                       at: [ pdf.bounds.left, 0 ],
                       align: :right,
                       size: 8
    end.render
  end

  private

  def formatted_date
    @activity.event_date&.strftime("%B %d, %Y") || "N/A"
  end

  def safe_value(value)
    value.to_s.strip.presence || "N/A"
  end

  def attendance_summary
    count = @activity.activity_signups.count
    if @activity.capacity.present?
      "#{count} of #{@activity.capacity} spots filled"
    else
      "#{count} attendees (no limit)"
    end
  end
end
