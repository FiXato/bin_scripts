#!/usr/bin/env ruby
# encoding: utf-8

require 'ruby-units'
if matchdata = ARGV.join(' ').match(/(?<source>\d+) ?(?<source_unit>\w+) (in|to) (?<target_unit>\w+)/)
  source = matchdata['source'].to_f
  source_unit = matchdata['source_unit']
  target_unit = matchdata['target_unit']
  case source_unit
  when 'F'
    case matchdata['target_unit']
    when 'C', 'Celcius', 'Celsius'
      result = ((source - 32.0) * (5.0/9.0))
      puts "((#{source}°#{source_unit} - 32.0) * (5.0/9.0)) = #{'%.2f' % result}°#{target_unit}"
    when 'K'
      result = ((source + 459.67) * (5.0/9.0))
      puts "((#{source}°#{source_unit} + 459.67) * (5.0/9.0)) = #{'%.2f' % result}°#{target_unit}"
    when 'N', 'Newton'
      result = ((source - 32.0) * (11/60))
      puts "((#{source}°#{source_unit} - 32.0) * (11⁄60)) = #{'%.2f' % result}°#{target_unit}"
    when 'Ré', 'Re', 'Réaumur'
      target_unit = 'Ré' if target_unit == 'Re'
      result = ((source - 32.0) * (4/9))
      puts "((#{source}°#{source_unit} - 32.0) * (4⁄9)) = #{'%.2f' % result}°#{target_unit}"
    when 'Rø', 'Rømer'
      result = ((source - 32.0) * (7/24) + 7.5)
      puts "((#{source}°#{source_unit} - 32.0) * (7⁄24) + 7.5) = #{'%.2f' % result}°#{target_unit}"
    when 'R', 'Rankine'
      result = (source + 459.67)
      puts "#{source}°#{source_unit} + 459.67 = #{'%.2f' % result}°#{target_unit}"
    when 'De', 'Delisle'
      result = ((212 - source) * (5.0/6.0))
      puts "(212 - #{source}°#{source_unit}) * (5⁄6) = #{'%.2f' % result}°#{target_unit}"
    when 'c'
      puts "Unknown target unit. Did you mean C? (Celsius)"
    when 'k'
      puts "Did you mean K? (Kelvin)"
    else
      # puts "Unknown target unit: #{matchdata['target_unit']}"
      unit = Unit("#{source} tempF")
      puts unit.convert_to("temp#{target_unit}").to_s("%0.2f").gsub("temp",'°')
    end
  when 'f'
    puts "Unknown source unit 'f'; did you mean F? (Fahrenheit)"
  else
    begin
      unit = Unit("#{source} #{source_unit}")
      puts unit.convert_to(target_unit).to_s("%0.2f")
    rescue ArgumentError => e
      puts "Unknown unit(s): #{e.message}"
    end
  end
end
