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
puts "VERSION:2.0"
puts "PRODID:https://github.com/ukd1/lvms-events"
puts "DESCRIPTION:Las Vegas Motor Speedway Events, parsed from https://www.lvms.com/events/. Code @ https://github.com/ukd1/lvms-events."
puts "UID:https://github.com/ukd1/lvms-events"
puts "URL:https://github.com/ukd1/lvms-events"
puts "SOURCE;VALUE=URI:https://raw.githubusercontent.com/ukd1/lvms-events/main/lvms-events.ics"
puts "IMAGE;VALUE=URI;DISPLAY=BADGE;FMTTYPE=image/png:https://www.lvms.com/images/header-lvms1.png"

event_by_id = {}

JSON.parse("{" + events_js.text.strip.split("\n")[1].strip.gsub('\'', '"') + "}").each do |date, event|
    doc = Nokogiri::HTML(event)
    link = doc.css('a')

    url = link.attribute('href')&.value
    url = 'https:' + url if url[0..1] == '//' if url

    id = link.attribute('data-id').value
    name = link.attribute('data-name').value
    dtstart = Date.strptime(link.attribute('data-date')&.value, '%m/%d/%Y')
    dtend = dtstart+1

    event_by_id[id] ||= {
        url: url,
        name: name,
        id: id,
        dtstart: dtstart,
        dtend: dtend,
    }

    event_by_id[id][:dtend] = dtend if event_by_id[id][:dtend] < dtend
end

event_by_id.each do |id, event|
    puts "BEGIN:VEVENT"
    puts "UID:LLVMS-#{id}"
    puts "SUMMARY:#{event[:name]}"
    puts "URL:#{event[:url]}"
    puts "LOCATION:Las Vegas Motor Speedway, 7000 Las Vegas Blvd. North, Las Vegas, NV 89115, USA"

    # https://www.kanzaki.com/docs/ical/dtstamp.html - apparently required
    puts "DTSTAMP:#{"%04d%02d%02d" % [event[:dtstart].year, event[:dtstart].month, event[:dtstart].day]}T000000Z"
    puts "DTSTART;VALUE=DATE:#{"%04d%02d%02d" % [event[:dtstart].year, event[:dtstart].month, event[:dtstart].day]}"
    puts "DTEND;VALUE=DATE:#{"%04d%02d%02d" % [event[:dtend].year, event[:dtend].month, event[:dtend].day]}"
    puts "ORGANIZER;CN=LVMS:MAILTO:ticketservices@lvms.com"
    puts "GEO:36.2724;-115.0104"
    puts "END:VEVENT"
end

puts "END:VCALENDAR"