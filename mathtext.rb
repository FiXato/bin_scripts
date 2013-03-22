#!/usr/bin/env ruby
# encoding: utf-8
begin

# Hack to prevent useless iconv warning from showing up in 1.9
oldverb = $VERBOSE; $VERBOSE = nil
require 'iconv'
$VERBOSE = oldverb

LATIN_RANGES = {
  :capital => 65..90,
  :small => 97..122,
}

MATHEMATICAL_RANGES = {
  :bold => [119808..119833, 119834..119859],
  :italic => [119860..119885, 119886..119911],
  :bold_italic => [119912..119937, 119938..119963],

  :script => [119964..119989, 119990..120015],
  :bold_script => [120016..120041, 120042..120067],

  :fraktur_bold => [120172..120197, 120198..120223],
  :fraktur => [120068..120093, 120094..120119],
}
translitator = Iconv.new("ASCII//TRANSLIT//IGNORE", "UTF-8")
conversion = ARGV.shift.to_sym
# puts conversion
input_text = translitator.iconv(ARGV.join(' ').strip).chars
output = ''
input_text.each do |char|
  next output << char if char == ' '
  begin
    i = 0
    target_range, target_index = LATIN_RANGES.map do |range_case, range|
      ret = [i, range.find_index(char.ord)]
      i += 1
      ret
    end.select{|range_case, index| !index.nil?}.flatten
    math_range = MATHEMATICAL_RANGES[conversion][target_range]
    output << math_range.to_a[target_index].chr(Encoding::UTF_8)
  rescue Exception
    output << char
  end
end
puts output
rescue Exception
  abort "error while running script"
end