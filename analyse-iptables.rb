#!/usr/bin/env ruby
# IPtables Logs Analyser
# (c) 2013, Filip H.F. "FiXato" Slagter.
require 'resolv'
require 'socket'
begin
  require 'slop'
rescue LoadError => e
  abort "You need the 'slop' library to run this script. You can install it using rubygems:\n  gem install slop"
end

CMD = File.basename(__FILE__)
class AnalyseIptables
  VERSION = '1.0'

  attr_accessor :grep_chains, :logfile
  def initialize(grep_chains={}, logfile="/var/log/iptables.log")
    @grep_chains={
      :drop => "egrep \"\[IPTABLES \S+ DROP\]\"",
      :drop_incoming => 'grep -F "[IPTABLES INC DROP]"',
      :drop_outgoing => 'grep -F "[IPTABLES OUT DROP]"',
      :drop_banned   => 'grep -F "[IPTABLES BAN DROP]"',
    }.merge(grep_chains)
    @logfile = File.expand_path(logfile)
    raise FileNotFound("Logfile '#{@logfile}' doesn't exist.") unless File.exist?(@logfile)
  end

  def ip2host(ip)
    @resolver ||= Resolv::DNS.new
    begin
      hostname = @resolver.getname(ip)
      return hostname
    rescue
      return ip
    end
  end

  def sort_and_count_chain(count)
    " | sort | uniq -c | sort -hr | head -n#{count}"
  end

  def insert_servname(str)
    if str.include?('PROTO=TCP')
      proto = 'tcp'
    elsif str.include?('PROTO=UDP')
      proto = 'udp'
    else
      return str
    end
    # puts str
            #  $1     $2       $3  $4
    str.gsub(/(\s)?(SPT=|DPT=)(\S+)(\s)?/).each do |match|
      # puts $3
      serv_name = '/' + Socket.getservbyport($3.to_i,proto) + '' rescue ''
      # puts serv_name
      "#{$1}#{$2}#{$3}#{serv_name}#{$4}"
    end
  end

#TODO: Tweak padding/alignment
  def puts_packets_for_IP(ip,type=:all,count=10)
      cmd = "grep -F \"#{ip}\" \"#{logfile}\""
      cmd += ' | ' + grep_chains[type] if [:drop, :drop_incoming, :drop_outgoing, :drop_banned].include?(type)
      cmd += " | egrep -o 'PROTO=(\\S+) SPT=(\\S+) DPT=(\\S+)'"
      cmd += ' | sed \'s/SPT=\\S\+\\s//\'' if type == :drop_incoming
      cmd += ' | sed \'s/DPT=\\S\+\\s//\'' if type == :drop_outgoing
      cmd += sort_and_count_chain(count)
     # puts cmd
      packetlines = `#{cmd}`.split("\n").map{|l|l = insert_servname(l); ' '*18 + l}
      puts packetlines.join("\n")
  end

  def dropped(type)
    cmd  = "#{grep_chains[:"drop_#{type}"]} \"#{logfile}\""
    cmd += " | egrep -o 'SRC=(\\S+)' | sed 's/SRC=//'" if type == :incoming
    cmd += " | egrep -o 'DST=(\\S+)' | sed 's/DST=//'" if type == :outgoing
    cmd += " | egrep -o '(SRC|DST)=(\\S+)'" if type == :banned
    cmd += sort_and_count_chain(10)
    # puts cmd

    #TODO: Exclude the server's IP from the banned matches

    `#{cmd}`.split("\n").each do |line|
      count,ip_string = line.split
      ip = ip_string.gsub('SRC=','').gsub('DST=','')
      if type == :banned
        puts '%3i: %20s (%s)' % [count,ip_string,ip2host(ip)]
      else
        puts '%3i: %16s (%s)' % [count,ip,ip2host(ip)]
      end

  #    puts ' ' * 20 + "Dropped Incoming:"
      puts_packets_for_IP(ip,:"drop_#{type}") if [:incoming, :outgoing, :banned].include?(type)

      if ARGV.include?('--match-all')
        puts ' ' * 20 + "99 Most Logged Packets:"
        puts_packets_for_IP(ip,:all,99)
      end
    end
    puts
  end

  def dropped_incoming
    puts "=== Most Dropped INCOMING trafic ==="
    dropped(:incoming)
  end

  def dropped_outgoing
    puts "=== Most Dropped OUTGOING trafic ==="
    dropped(:outgoing)
  end

  def dropped_banned
    puts "=== Most Dropped BANNED trafic ==="
    dropped(:banned)
  end
end

# 'IPtables Logs Analyser'
# 'Get various statistics from your IPtables logs.'
#analyse-iptables dropped
#analyse-iptables dropped incoming,outgoing,banned
#analyse-iptables group dpt,spt,src,dst

class FileNotFound < ArgumentError; end

class Slop
  def command_var
    instance_variable_get('@command')
  end
end


begin
  iptlog = AnalyseIptables.new()
rescue FileNotFound => e
  abort(e.message)
end

opts = Slop.parse(:help => true) do
  on '--version', 'Print the version' do
    puts "Version #{AnalyseIptables::VERSION}"
  end

  command 'dropped' do
    # on :v, :verbose, 'Enable verbose mode'
    # on :name=, 'Your name'
    # on 'p', 'password', 'An optional password', argument: :optional
    on 'i', 'incoming', 'Show dropped incoming packets', argument: :optional
    on 'o', 'outgoing', 'Show dropped outgoing packets', argument: :optional
    on 'b', 'banned', 'Show dropped banned packets', argument: :optional

    run do |opts, args|
      iptlog.dropped_incoming if incoming?
      iptlog.dropped_outgoing if outgoing?
      iptlog.dropped_banned if banned?
      # puts "You ran '#{command_var}' with options #{opts.to_hash} and args: #{args.inspect}"
      puts opts unless incoming? || outgoing? || banned?
      exit
    end
  end
end
puts opts