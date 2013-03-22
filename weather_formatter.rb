#!/usr/bin/env ruby
#encoding: utf-8

class WeatherFormatter
  #unicon approach stolen from Azurebot
  UNICON = {
    :clear => ["☾","clear"],
    :cloudy => ["☁","cloudy"],
    :flurries => ["☃","flurries"],
    :fog => ["☁","fog"],
    :hazy => ["☁","hazy"],
    :mostlycloudy => ["☁", "mostly cloudy"],
    :mostlysunny => ["☀", "mostly sunny"],
    :partlycloudy => ["☁☀", "partly cloudy"],
    :partlysunny => ["☀☁", "partly sunny"],
    :rain => ["☂", "rain"],
    :sleet => ["☂☃", "sleet"],
    :snow => ["☃", "snow"],
    :sunny => ["☀", "sunny"],
    :tstorms => ["☈", "thunderstorms"],
    :unknown => ["☄", "unknown"]
  }
  BOLD = 2.chr
  REVERSE = 22.chr
  ITALIC = 29.chr
  UNDERLINE = "\037"
  
  def bold(str)
    [BOLD,str,BOLD].join('')
  end
  
  def reverse(str)
    [REVERSE,str,REVERSE].join('')
  end
  
  def italic(str)
    [ITALIC,str,ITALIC].join('')
  end
  
  def underline(str)
    [UNDERLINE,str,UNDERLINE].join('')
  end
  
  def format_items(&block)
    items = []
    block.call(items)
    return nil if items.size == 0
    '[%s]' % items.join(' ')
  end

  def format_wind(wind)
    return nil unless wind
    format_items do |items|
      items << ('%s kph' % wind.kph) if wind.kph
      items << ('%s°' % wind.degrees) if wind.degrees
      items << ('%s' % wind.direction) if wind.direction
    end
  end

  def format_humidity(w)
    format_items do |items|
      items << "#{bold('Humidity')}: %s" % w.humidity if w.humidity
      items << ('%s%% P.O.P.' % w.pop||0) unless w.pop.nil?
    end
  end

  def icon_condition(c)
    return nil unless c.icon
    conditions = UNICON[c.icon.to_sym]
    '%s (%s)' % [conditions[1], conditions[0]]
  end

  def dater(c)
    items = []
    items << c.updated_at.to_s(false) if c.updated_at
    items << c.current_at if c.current_at
    return 'Today' if items.size == 0
    return items.compact.join(' ')
  end
  
  def get_results(w)
    w.sources.each do |source|
      w_source = w.source(source)
      c = w_source.current
      td = w_source.for(w_source.now)
      tm = w_source.for(w.tomorrow.date)
      location = [w_source.location.name || w_source.location, w_source.station.id || w_source.station].reject{|i| i.to_s.strip == ''}.join(', ')
      windchill = ('feels like %s ' % bold("#{c.wind_chill.c}°C") rescue '')
      wind_info = [format_wind(c.wind), format_humidity(c), c.condition, bold(icon_condition(c))].compact.join(' ')
      location_info = underline(bold('[%s: %s]' % [source, location]))
      colours_today = "" #"\003" + "15,01"
      colours_tomorrow = "" #"\003" + "14,01"
      today = colours_today + "#{location_info} #{italic(reverse(dater(c)))}: #{bold("#{c.temperature.c}°C")} #{windchill}(#{bold('Min:')} #{td.low.c}°C, #{bold('Max:')} #{td.high.c}°C) #{wind_info}"
      tomorrow = colours_tomorrow + italic(reverse("Tomorrow (#{tm.date})")) + ': Min: %s°C, Max: %s°C %s' % [
        tm.low.c, 
        tm.high.c,
        [format_wind(tm.wind), format_humidity(tm), tm.condition].compact.join(' '),
      ]
      puts [today, tomorrow].join(' - ')
    end
  end
end

