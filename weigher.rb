#!/usr/bin/env ruby
#encoding: utf-8
#
# weigher: Keep track of your body weight and graph it over time using spark graphs and GNU Plot.
# Usage: weigher.rb [--add] [--graphs]
# Examples:
#  - Get graphs of your recorded weights for the past month: `weigher --graphs`
#  - Enter your current weight and get the difference from your last measurement: `weigher --add`
#  - Get your last measurement: `weigher`
require 'yaml'
require 'date'

class Weigher
  attr_accessor :history, :filename, :plotdatafile

  def initialize(filename="~/.weights.yaml", plotdatafile="~/.weights.plotscript")
    @filename = File.expand_path(filename)
    if File.exist?(@filename)
      @history = YAML.load_file(@filename)
    else
      puts "#{@filename} doesn't exist. Initialised with empty history."
      @history = {}
    end
    sorted_history(true)
    @plotdatafile = File.expand_path(plotdatafile)
  end

  def sorted_history(clear=false)
    @sorted_history = nil if clear
    @sorted_history ||= Hash[@history.sort_by{|ts,weight|ts}]
  end

  def last
    sorted_history.to_a.last
  end

  def last_measure_time
    last.first
  end

  def last_measurement
    last.last
  end

  def first
    sorted_history.first
  end

  def first_measure_time
    first.first
  end

  def first_measurement
    first.last
  end

  def history_spark
    `spark #{sorted_history.values.join(' ')}`
  end

  def history_graph
    plotscript=<<EOS
set title 'Weight diagram for Filip H.F. \"FiXato\" Slagter'
set terminal dumb 255 80
set key off
set ylabel "Weight (Kilogrammes)"
set style data fsteps
set xlabel "Date"
# set timefmt x "%Y-%m-%d %H:%M:%S"
# set timefmt x "%m-%d %H:%M"
set xrange ["#{(DateTime.now << 1).to_time.utc.to_i}":"#{Time.now.utc.to_i}"]
set datafile separator "|"
plot '-' with lines
EOS
    sorted_history.each do |date, weight|
      # ts = date.utc.to_s.split('.').first.split(' UTC').first.gsub(/\s/,'_')
      # ts = date.utc.to_s.split('.').first.split(' UTC').first
      # ts = date.utc.strftime("%y%m%d.%H%M")
      # ts = ((date.utc.year.to_i - Time.now.utc.year.to_i) * 365.25).to_s + date.utc.yday.to_s + date.utc.strftime("%H%M")
      ts = date.utc.to_i
      data = "#{ts}|#{weight}\n"
      plotscript << data
    end
    # puts plotscript
    File.open(plotdatafile,"w") {|f| f.write(plotscript)}
    `gnuplot -e "load '#{plotdatafile}'"`
  end

  def difference
    diff = (last_measurement.to_f - sorted_history.to_a[-2].last.to_f).round(1)
  end

  def add(weight, timestamp=Time.now)
    history[timestamp] = weight
    sorted_history(true)
    difference rescue last_measurement
  end

  def add_from_gets
    puts "Please input your current weight in kilograms:"
    current = $stdin.gets.strip.to_f rescue nil
    add(current)
  end

  def save
    File.open(filename,"w") do |f|
      f.puts history.to_yaml
    end
  end
end

weigher = Weigher.new  
if ARGV.include?('--graphs')
  puts "Measurements: ", weigher.sorted_history.to_yaml, ""
  puts "Spark graph:", weigher.history_spark, ""
  puts "GNU Plot Graph: ", weigher.history_graph, ""
end

if weigher.sorted_history.size > 0
  previous = weigher.last
  puts "Your previous weight at #{previous.first} was: #{previous.last}"
end

if ARGV.include?('--add')
  difference = weigher.add_from_gets
  puts "Difference: #{difference} Kg"
  weigher.save
end
