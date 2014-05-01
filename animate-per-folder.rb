#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'

class String
  def to_range
    items = self.split(/\.\.\.?|[,]/).map{|_|_.to_i}
    if self.include?('...')
      items[0]...items[1]
    elsif self.include?('..')
      items[0]..items[1]
    elsif self.include?(',')
      return *items
    end
  end
end

@dir = ARGV[ARGV.index('--path') + 1] if ARGV.include?('--path')
@dir ||= '.'

DEFAULT_ANIMATIONS_PATH = File.join(@dir, '_Animations')
DEFAULT_INTERMEDIATE_PATH = File.join(@dir, '_Intermediate')
DEFAULT_DELAYS = [16, 25, 40]
DEFAULT_ANIMATION_DIMENSIONS = '1024x'

def arg_from_param(key)
  ARGV[ARGV.index(key) + 1] if ARGV.include?(key)
end

@delays = ARGV[ARGV.index('--delays') + 1].split(',') if ARGV.include?('--delays')
@delays ||= DEFAULT_DELAYS

@animation_dimensions = arg_from_param('--animation-dimensions')
@animation_dimensions ||= DEFAULT_ANIMATION_DIMENSIONS
puts "Animation dimensions set to #{@animation_dimensions}"

@trim_frames = arg_from_param('--trim-frames').to_i
@frame_range = arg_from_param('--frame-range').to_range rescue nil

@convert_args = ' ' + arg_from_param('--convert-args')
@convert_args ||= ''

def skip_existing?
  return @skip_existing unless @skip_existing.nil? 
  @skip_existing = ARGV.include?('--skip-existing')
end

def create_intermediate_files?
  return @intermediate_files unless @intermediate_files.nil? 
  @intermediate_files = ARGV.include?('--create-intermediate-files')
end  

def create_back2front_animation?
  return @create_back2front_animation unless @create_back2front_animation.nil? 
  @create_back2front_animation = ARGV.include?('--create-back2front-animation')
end  

def skip_normal_animation?
  ARGV.include?('--skip-normal-animation')
end  

def optimise
  "-layers optimize " if ARGV.include?('--optimize') || ARGV.include?('--optimise')
end

def create_intermediate_files(files, set_name, offset=0)
  FileUtils.mkdir_p(File.join(DEFAULT_INTERMEDIATE_PATH, set_name))
  intermediate_filepaths = []

  files.each_with_index do |f,index|
    extension = f.split('.').last
    new_filename = '%s-%03i.%s' % [set_name,index+offset,extension]
    new_filepath = File.join(intermediate_path, new_filename)
    intermediate_filepaths << File.expand_path(new_filepath)

    if File.exist?(new_filepath) and skip_existing?
      puts "Skipped #{new_filepath} because it already exists"
      next
    end

    puts "Copying #{f} to #{new_filepath}"
    FileUtils.cp(f, new_filepath)
  end

  return intermediate_filepaths
end

def create_animation(files, delay, target_folder, prefix)
  target_file = File.join(target_folder, "#{prefix}animation-#{delay}.gif")
  if File.exist?(target_file) and skip_existing?
    puts "Skipped #{target_file} because it already exists"
    return false
  end
  puts "Converting all #{files.size} frames into animation with #{delay}/100th delay stored at #{target_file}"
  command = "convert#{@convert_args} #{optimise}-delay #{delay} #{files.map{|f|'"%s"[%s]' % [f, @animation_dimensions]}.join(' ')} -loop 0 \"#{target_file}\""
  # puts command
  puts `#{command}`
end

def create_animations_for_default_profiles(files, prefix)
  animations_path = File.join(DEFAULT_ANIMATIONS_PATH)
  FileUtils.mkdir_p(animations_path)
  @delays.each do |delay|
    create_animation(files, delay, animations_path, prefix)
  end
end

def animation_prefix(safe_folder_prefix,type)
  prefix = "#{safe_folder_prefix}-#{type}-"
  prefix += "trimmed#{@trim_frames}-" if @trim_frames > 0
  prefix += "#{@animation_dimensions}resize-" if @animation_dimensions
  prefix += "range#{@frame_range}-" if @frame_range
  prefix
end

#Dirs starting with _ are excluded; only jpg's and png's are accepted for now
path = File.join(@dir, '[^_]*/*.{jpg,JPEG,JPG,png,PNG}') 
files_per_folder = Dir.glob(path).group_by{|f|File.dirname(f).split(File::SEPARATOR).last}
files_per_folder.each do |folder, files|
  puts "Preparing #{files.size} files in #{folder}"

  if @frame_range
    if @frame_range.kind_of?(Array)
      files = files[*@frame_range]
    elsif @frame_range.kind_of?(Range)
      files = files[@frame_range]
    else
      puts "#{@frame_range} is an incorrectly formatted range"
    end
  end
  if @trim_frames and @trim_frames > 0
    files = files.select.with_index{|_,i| (i+1) % @trim_frames == 0}
  end
  files.map!{|f|File.expand_path(f)}
  safe_folder_prefix = folder.gsub(/[^a-zA-Z0-9_'-]/, '')

  files = create_intermediate_files(files, folder) if create_intermediate_files?

  unless skip_normal_animation?
    puts "Will convert #{files.size} frames to the default set of animations"
    create_animations_for_default_profiles(files, animation_prefix(safe_folder_prefix, 'normal'))
  end

  if create_back2front_animation?
    offset = files.size
    reverse_files = files[1...-1].reverse
    
    reverse_files = files if reverse_files.size == 0 and skip_normal_animation?
    if reverse_files.size > 0
      reverse_files = create_intermediate_files(reverse_files, folder, offset) if create_intermediate_files?

      puts "Will convert #{files.size} files + #{reverse_files.size} reversed frames to the default set of back-to-front animations"
      create_animations_for_default_profiles(files + reverse_files, animation_prefix(safe_folder_prefix, 'back2front'))
    else
      puts "Animation has too little frames to require a back-to-front animation."
    end
  end  
end