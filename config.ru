require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "date"

require "icalendar"

require "feedzirra"
require "pp"

Feedzirra::Feed.add_common_feed_entry_element("softlayer:location",  :as => :sl_location)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:service",   :as => :sl_service)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:startdate", :as => :sl_start_date)
Feedzirra::Feed.add_common_feed_entry_element("softlayer:enddate",   :as => :sl_end_date)

ONE_WEEK = 3600 * 60 * 24 * 7

class SoftlayerStatus < Sinatra::Base
  get "/softlayer.ics" do
    start_time = params[:start] ? Time.parse(params[:start]) : (Time.now - ONE_WEEK)
    end_time = params[:end] ? Time.parse(params[:end]) : (start_time + 4 * ONE_WEEK)
    datacenters = [ *params[:dc] ].flatten

    events = get_softlayer_events(
      :start => start_time,
      :end => end_time,
      :datacenters => datacenters
    )

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

    content_type "text/plain"
    ical.to_ical
  end

  def get_softlayer_events(limits = {})
    feed = Feedzirra::Feed.fetch_and_parse("http://rss.softlayer.com/maintenance.xml")
    feed.entries.map do |entry|
      parse_feed_entry(entry)
    end
  end

  def parse_feed_entry(entry)
    event = {}
    dc = entry.sl_location.split(/\W+/).compact.uniq.sort
    event[:title] = "#{dc.join('/')}: #{entry.sl_service}"
    event[:datacenters] = dc
    event[:description] = entry.summary
    event[:start_time] = Time.parse(entry.sl_start_date.gsub('GMT+0000', 'UTC')) - 3600 * 5
    event[:end_time] = Time.parse(entry.sl_end_date.gsub('GMT+0000', 'UTC')) - 3600 * 5
    OpenStruct.new(event)
  end
end


#--------------------------------------------------------------------------------------------------
run SoftlayerStatus