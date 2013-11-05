#!/usr/bin/env ruby
require 'resolv'
PREFIX_DROP_INCOMING = "[IPTABLES INC DROP]"
PREFIX_DROP_OUTGOING = "[IPTABLES OUT DROP]"
LOG = "/var/log/iptables.log"

def ip2host(ip)
  @resolver ||= Resolv::DNS.new
  begin
    hostname = @resolver.getname(ip)
    return hostname
  rescue
    return ip
  end
end

def puts_packets_for_IP(ip,type=:all,count=10)
    cmd = "grep -F \"#{ip}\" \"#{LOG}\""
    cmd += " | grep -F \"DROP\"" if type == :drop
    cmd += " | grep -F \"#{PREFIX_DROP_INCOMING}\"" if type == :drop_incoming
    cmd += " | grep -F \"#{PREFIX_DROP_OUTGOING}\"" if type == :drop_outgoing
    cmd += " | grep -F \"ACCEPT\"" if type == :accept
    sed = ''
    sed += '| sed \'s/SPT=\\S\+//\' ' if type == :drop_incoming
    sed += '| sed \'s/DPT=\\S\+//\' ' if type == :drop_outgoing
    cmd += " | egrep -o 'PROTO=(\\S+) SPT=(\\S+) DPT=(\\S+)' #{sed}| sort | uniq -c | sort -hr | head -n#{count}"
#    puts cmd
    packetlines = `#{cmd}`.split("\n").map{|l| ' '*22 + l}
    puts packetlines.join("\n")
end

if ARGV.include?('--most-dropped-inc')
  puts "=== Most Dropped INCOMING trafic ==="
  cmd = "grep -F \"#{PREFIX_DROP_INCOMING}\" \"#{LOG}\"|egrep -o 'SRC=(\\S+)' | sort | uniq -c | sort -hr | head -n10"
  puts cmd
  loglines = `#{cmd}`.gsub('SRC=','').split("\n").each do |line| 
    count,ip = line.split
    puts '%5i: %16s (%s)' % [count,ip,ip2host(ip)]

#    puts ' ' * 20 + "Dropped Incoming:"
    puts_packets_for_IP(ip,:drop_incoming)
    
    if ARGV.include?('--match-all')
      puts ' ' * 20 + "99 Most Logged Packets:"
      puts_packets_for_IP(ip,:all,99)
    end
  end
end

if ARGV.include?('--most-dropped-out')
  puts "=== Most Dropped OUTGOING trafic ==="
  cmd = "grep -F \"#{PREFIX_DROP_OUTGOING}\" \"#{LOG}\"|egrep -o 'DST=(\\S+)' | sort | uniq -c | sort -hr | head -n10"
  puts cmd
  loglines = `#{cmd}`.gsub('DST=','').split("\n").each do |line| 
    count,ip = line.split
    puts '%5i: %16s (%s)' % [count,ip,ip2host(ip)]
#    puts ' ' * 20 + "Dropped Outgoing:"
    puts_packets_for_IP(ip,:drop_outgoing)

    if ARGV.include?('--match-all')
      puts ' ' * 20 + "99 Most Logged Packets:"
      puts_packets_for_IP(ip,:all,99)
    end
  end
end
