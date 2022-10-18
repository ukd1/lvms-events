# https://datatracker.ietf.org/doc/html/draft-daboo-icalendar-extensions
require 'httparty'
require 'nokogiri'
require 'json'

response = HTTParty.get('https://www.lvms.com/events/')
if response.code != 200
    raise "Error: #{response.code}"
end

doc = Nokogiri::HTML(response.body)
events_js = doc.css('script').find do |script|
    script.text[0..20].strip[0..11] == "var sfEvents"
end

puts "BEGIN:VCALENDAR"
puts "NAME:LVMS Events"
puts "DESCRIPTION:Las Vegas Motor Speedway Events, parsed from https://www.lvms.com/events/. Code @ https://github.com/ukd1/lvms-events."
puts "UID:https://github.com/ukd1/lvms-events"
puts "URL:https://github.com/ukd1/lvms-events"
puts "SOURCE;VALUE=URI:https://raw.githubusercontent.com/ukd1/lvms-events/lvms-events.ics"
puts "IMAGE;VALUE=URI;DISPLAY=BADGE;FMTTYPE=image/png:https://www.lvms.com/images/header-lvms1.png"

JSON.parse("{" + events_js.text.strip.split("\n")[1].strip.gsub('\'', '"') + "}").each do |date, event|
    doc = Nokogiri::HTML(event)
    link = doc.css('a')

    url = link.attribute('href')&.value
    url = 'https:' + url if url[0..1] == '//' if url

    id = link.attribute('data-id').value
    name = link.attribute('data-name').value
    dtstart = Date.strptime(link.attribute('data-date')&.value, '%m/%d/%Y')
    dtend = dtstart+1

    # puts
    puts "BEGIN:VEVENT"
    puts "UID:LLVMS-#{id}"
    puts "SUMMARY:#{name}"
    puts "URL:#{url}"
    puts "DTSTART;VALUE=DATE:#{"%04d%02d%02d" % [dtstart.year, dtstart.month, dtstart.day]}"
    puts "DTEND;VALUE=DATE:#{"%04d%02d%02d" % [dtend.year, dtend.month, dtend.day]}"
    puts "ORGANIZER;CN=LVMS:MAILTO:ticketservices@lvms.com"
    puts "GEO:36.2724;-115.0104"
    puts "END:VEVENT"
    # puts "\t\t#{event}"
end


puts "END:VCALENDAR"