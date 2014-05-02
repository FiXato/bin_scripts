#!/usr/bin/env ruby
# encoding: utf-8
require 'yaml'
require 'fileutils'
VERBOSE ||= ARGV.delete('--verbose')
SOURCE_APPS_DIR = File.expand_path('~/Applications')
STEAMAPPS_DIR = File.expand_path('~/Library/Application\ Support/Steam/SteamApps')

def debug(*args)
  return unless VERBOSE
  puts *args
end

def execute_commands?
  @execute_commands ||= ARGV.delete('--execute')
end

def puts_and_execute(command)
  puts command
  puts `#{command}` if execute_commands?
end

def user_apps
  # FIXME: do this in the initialize of the class.
  execute_commands? # ensure the --execute flag isn't part of the apps passed on the commandline
  @user_apps ||= ARGV.empty? ? Dir.glob(File.join(SOURCE_APPS_DIR,'*.app')) : ARGV
end
user_apps_with_names = user_apps.map do |app|
  basename = File.basename(app)
  app_name = basename.gsub(/\.app$/,'')
  search_string = app_name.gsub(/\s+/,'*')
  [
    app, 
    search_string,
  ]
end
apps_with_icons = user_apps_with_names.map do |app, app_name|
  search_string = "common/*#{app_name}*/**/{*#{app_name}*,*}.icns"
  search_path   = File.join(STEAMAPPS_DIR, search_string)
  [
    app,
    icons_for_steam_app = Dir.glob(search_path, File::FNM_CASEFOLD),
  ]
end
steam_apps_with_icons = apps_with_icons.reject{|app,icons|icons.empty?}
steam_apps_with_icons.each do |app, icons|
  icons_list = icons.map{|icon|" — #{icon}"}.uniq
  debug "#{app} has #{icons.size} available icons:\n#{icons_list.join("\n")}" if icons_list.size > 2
end
icons_to_set = steam_apps_with_icons.map{|app, icons| [app, icons.first].join(' => ')}
debug "The following icons would be set:", icons_to_set.join("\n")


debug "", "Proceeding with setting icons"

unless execute_commands?
  puts "If you want to set the icons, pass along --execute, otherwise just run the following commands manually:"
end

steam_apps_with_icons.each do |app_folder, icons|
  source_icon = icons.first
  resource_icon = File.join(app_folder,"Contents/Resources/Icon-#{File.basename(app_folder).gsub(/\.app$/,'').gsub(/[^a-zA-Z0-9_-]/,'')}.icns")
  temp_resource = File.join(app_folder,'Contents/Resources/tempicns.rsrc')

  puts "", "Setting #{source_icon} as icon for #{app_folder}"

  # Take an image and make the image its own icon:
  if execute_commands?
    FileUtils.cp(source_icon,resource_icon)
  else
    puts 'cp "%s" "%s"' % [source_icon,resource_icon]
  end
  puts_and_execute "sips -i \"#{resource_icon}\""
  
  # Extract the icon to its own resource file:
  puts_and_execute 'DeRez -only icns "%s" > "%s"' % [resource_icon, temp_resource]
  
  # append this resource to the folder you want to icon-ize.
  puts_and_execute 'Rez -append "%s" -o $\'%s/Icon\r\'' % [temp_resource, app_folder.gsub("'","\'")]

  # Use the resource to set the icon.
  puts_and_execute 'SetFile -a C "%s"' % app_folder

  # Hide the Icon\r file from Finder.
  puts_and_execute 'SetFile -a V $\'%s/Icon\r\'' % [app_folder.gsub("'","\'")]
end