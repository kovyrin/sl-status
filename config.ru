require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "date"
require "icalendar"
require "feedzirra"

ROOT_DIR = File.dirname(__FILE__)

#---------------------------------------------------------------------------------------------------
# Configure SL-specific feed item fields
Feedzirra::Feed.add_common_feed_entry_element("softlayer:location",  :as => :sl_location)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:service",   :as => :sl_service)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:startdate", :as => :sl_start_date)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:enddate",   :as => :sl_end_date)

#---------------------------------------------------------------------------------------------------
class SoftlayerStatus < Sinatra::Base
  set :public_folder, "#{ROOT_DIR}/public"
  set :views, "#{ROOT_DIR}/views"

  # Render home page
  get '/' do
    erb :home
  end

  # Render softlayer feed
  get "/softlayer.ics" do
    datacenters = [ *params[:dc] ].flatten.compact.map { |dc| dc.split(',') }.flatten.uniq
    events = get_softlayer_events(:datacenters => datacenters)
    format_ical_feed(events)
  end

  def format_ical_feed(events)
    ical = Icalendar::Calendar.new

    events.each do |event|
      ievent = Icalendar::Event.new
      ievent.start = event.start_time.to_datetime.utc
      ievent.start.icalendar_tzid = "UTC"

      ievent.end = event.end_time.utc.to_datetime
      ievent.end.icalendar_tzid = "UTC"

      ievent.summary = event.title
      ievent.description = event.description
      ievent.location = event.datacenters.join(', ')
      ievent.klass = 'PUBLIC'
      ical.add(ievent)
    end

    content_type "text/calendar"
    ical.to_ical
  end

  def get_softlayer_events(limits = {})
    puts "Limits: #{limits.inspect}"
    feed = Feedzirra::Feed.fetch_and_parse("http://rss.softlayer.com/maintenance.xml")
    events = []

    feed.entries.each do |entry|
      event = parse_feed_entry(entry)
      next if limits[:datacenters].any? && (limits[:datacenters] & event.datacenters).empty?
      events << event
    end

    events.sort_by { |e| e.start_time }
  end

  def parse_feed_entry(entry)
    event = {}
    dc = entry.sl_location.split(/\W+/).compact.uniq.sort
    event[:datacenters] = dc

    event[:start_time] = Time.parse(entry.sl_start_date.gsub('GMT+0000', 'UTC'))
    event[:end_time] = Time.parse(entry.sl_end_date.gsub('GMT+0000', 'UTC'))

    length = (event[:end_time] - event[:start_time]) / 3600
    event[:title] = "#{dc.join('/')}: #{entry.sl_service} (#{length.to_i} hours)"

    body = entry.summary
    body = body.gsub(/^.*={50,}(.*)={50,}.*/m, '\1').split("\n").map { |l| l.gsub(/[\s\=]+$/, '').strip }.join("\n")
    event[:description] = body.strip

    OpenStruct.new(event)
  end
end

#---------------------------------------------------------------------------------------------------
run SoftlayerStatus
