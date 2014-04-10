#!/usr/bin/env ruby
# Command of the day
# Picks a random executable from your path until it finds one with a manpage.
# Use this to learn about some of the really obscure yet really useful scripts that are already on your system.
DEBUG=ARGV.include?('--debug')

require 'timeout'

def debug(*args)
  puts args if DEBUG
end

def has_man_page?(cotd_basename)
  debug "  Looking for man-page for: #{cotd_basename}"
  man_path = Timeout::timeout(2) {`man -w #{cotd_basename} 2>&1`}
  if man_path.split("[\n\r]")[0].include?('No manual entry for')
    debug "  No man-page found.","" 
    return false
  end
  debug "  man-page found at: #{man_path}","" 
  return true
rescue Timeout::Error
  debug "    Timeout while looking for man-page for #{cotd_basename}"
  false
end

 
files = ENV["PATH"].split(":").uniq.compact.map { |path|
  Dir.glob(File.join(path,'*')).select {|file| File.file?(file) && File.executable?(file)}
}.flatten.compact.uniq
debug("#{files.size} commands found")
 
begin
  cotd = files.sample rescue files[rand(files.size)]
  cotd_basename = File.basename(cotd)
  debug("Random command picked: #{cotd_basename} (#{cotd})")
end until has_man_page?(cotd_basename)

puts "Command of the day is: #{cotd}"
if ARGV.include?('--man')
  exec "man #{cotd_basename}"
else
  puts "Read more about it: `man #{cotd_basename}`"
  puts "Pass --man to automatically show the man-page."
end
