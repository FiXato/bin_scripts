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

DEFAULT_ANIMATION_DIMENSIONS = '1024x'
DEFAULT_ANIMATIONS_DIR_NAME = '_Animations'
DEFAULT_INTERMEDIATE_DIR_NAME = '_Intermediate'
FILES_MASK = '[^_]*/*.{jpg,JPEG,JPG,png,PNG}' #Dirs starting with _ are excluded; only jpg's and png's are accepted for now
PROFILES = {
  'auto-awesome' => {
    '--skip-existing' => true,
    '--create-back2front-animation' => true,
    '--delays' => '20,40',
    '--animation-dimensions' => '1280x'
  }
}
AVAILABLE_OPTIONS = {
  flags: {
    '--auto-awesome'                => 'sets a number of default flags and options.',
    '--skip-existing'               => 'skip existing files. If an animation or intermediate file already exists, it will not be overwritten.',
    '--create-intermediate-files'   => 'create intermediate files. It will copy all used frames to an intermediate files folder and rename them to include their index. Use this if you need to post-process the frames',
    '--create-back2front-animation' => 'create a "back to front"-animation. Normally an animated gif will loop back to the first frame after it has reached the end. This option will add additional frames to reverse back to the front of the animation, for a smoother loop.',
    '--skip-normal-animation'       => 'skip the creation of the normal animation. Useful if you only want to create a back-to-front animation.',
    '--optimise'                    => 'try to optimise the animation using the "-layers optimize" ImageMagick argument.',
    '--optimize'                    => 'see --optimise',
  },
  options: {
    '--base-path'             => 'the base path from which this utility will search and in which it will create directories.',
    '--delays'                => 'comma-separated list of delays to be used. An animation will be created for each delay specified.', 
    '--animation-dimensions'  => 'target animation geometry dimensions in the form of WidtxHeight, where either can be left blank. Defaults to %s' % DEFAULT_ANIMATION_DIMENSIONS,
    '--files-range'           => 'range of files to use. 50..100 will for instance drop anything up to the 50th file, and anything after the 100th file. 3,50 will use 50 files starting with the 3rd file, and -5...-1 will use the fifth last file up to the last file (non-inclusive).',
    '--select-nth-frames'     => 'number of nth frames to select from the files list. 3 would for instance pick every 3rd frame, and drop the rest, thus reducing the number of frames by 2/3rd. Selection is applied after the files range (if specified).',
    '--convert-args'          => 'additional convert args. If your args contain spaces, enclose the string with double quotes.',
  }
}

def parse_profiles
  if @options['--auto-awesome']
    @options = PROFILES['auto-awesome'].merge(@options.reject{|k,v|v.nil?})
  end
end

def parse_options
  @options = {}
  AVAILABLE_OPTIONS[:flags].keys.each{|flag| @options[flag] = ARGV.delete(flag)}
  AVAILABLE_OPTIONS[:options].keys.each{|option| @options[option] = option_from_param(option)}
  parse_profiles
  @options
end

def options
  @options || parse_options
end

def option_from_param(key)
  return nil unless ARGV.include?(key)
  ARGV[ARGV.index(key) + 1]
end

def base_dir
  @base_dir ||= options['--base-path'] || '.'
end

def animations_path
  File.join(base_dir, DEFAULT_ANIMATIONS_DIR_NAME)
end

def intermediate_path
  File.join(base_dir, DEFAULT_INTERMEDIATE_DIR_NAME)
end


def delays
  @delays ||= (options['--delays'].split(',') || [nil])
end

def animation_dimensions
  @animation_dimensions ||= options['--animation-dimensions'] || DEFAULT_ANIMATION_DIMENSIONS
end

def frames_to_select
  @frames_to_select ||= options['--select-nth-frames'].to_i
end

def frame_range
  @frame_range ||= options['--files-range'].to_range rescue nil
end

def additional_convert_args
  options['--convert-args']
end

def skip_existing?(filepath)
  options['--skip-existing'] and File.exist?(filepath)
end

def create_intermediate_files?
  options['--create-intermediate-files']
end  

def create_back2front_animation?
  options['--create-back2front-animation']
end  

def skip_normal_animation?
  options['--skip-normal-animation']
end  

def optimise?
  options['--optimise']||options['--optimize']
end

def create_intermediate_files(files, set_name, offset=0)
  FileUtils.mkdir_p(File.join(intermediate_path, set_name))
  intermediate_filepaths = []

  files.each_with_index do |f,index|
    extension = f.split('.').last
    new_filename = '%s-%03i.%s' % [set_name,index+offset,extension]
    new_filepath = File.join(intermediate_path, new_filename)
    intermediate_filepaths << File.expand_path(new_filepath)

    puts "Skipped #{new_filepath} because it already exists" and next if skip_existing?(new_filepath)
    puts "Copying #{f} to #{new_filepath}" and FileUtils.cp(f, new_filepath)
  end

  return intermediate_filepaths
end

def create_animation(files, delay, target_folder, prefix)
  puts "There are no input files specified for this animation" and return false if files.size < 1

  animation_name = "#{prefix}animation"
  animation_name += "-delay#{delay}" if delay
  target_file = File.join(target_folder, animation_name + '.gif')

  puts "Skipped #{target_file} because it already exists" and return false if skip_existing?(target_file)

  puts "Will convert all #{files.size} frames into animation: #{target_file}"
  command = ['convert']
  command << additional_convert_args
  command << '-layers optimize' if optimise?
  command << "-delay #{delay}" if delay
  files.each do |f|
    file_string = '"%s"' % f
    file_string += "[#{animation_dimensions}]" if animation_dimensions
    command << file_string
  end
  command << '-loop 0'
  command << '"%s"' % target_file
  command = command.join(' ')
  puts command
  puts `#{command}`
end

def create_animations_for_default_profiles(files, prefix)
  FileUtils.mkdir_p(animations_path)
  delays.each do |delay|
    create_animation(files, delay, animations_path, prefix)
  end
end

def animation_prefix(safe_folder_prefix,type)
  prefix = "#{safe_folder_prefix}-#{type}-"
  prefix += "trimmed#{frames_to_select}-" if frames_to_select > 0
  prefix += "resize#{animation_dimensions}-" if animation_dimensions
  prefix += "range#{frame_range}-" if frame_range
  prefix += "cropped-" if additional_convert_args.to_s.include?('-crop')
  prefix
end

def files_per_folder
  Dir.glob(File.join(base_dir, FILES_MASK)).group_by{|f|File.dirname(f).split(File::SEPARATOR).last}
end

def limit_frame_range(files)
  if frame_range
    if frame_range.kind_of?(Array)
      files = files[*frame_range]
    elsif frame_range.kind_of?(Range)
      files = files[frame_range]
    else
      puts "#{frame_range} is an incorrectly formatted range"
    end
  end
  files
end

def select_nth_frames(files)
  return files if frames_to_select < 2
  files.select.with_index{|_,i| (i+1) % frames_to_select == 0}
end

files_per_folder.each do |folder, files|
  puts "Preparing #{files.size} files in #{folder}"
  safe_folder_prefix = folder.gsub(/[^a-zA-Z0-9_'-]/, '')
  
  files = limit_frame_range(files)
  files = select_nth_frames(files)
  files.map!{|f|File.expand_path(f)}
  files = create_intermediate_files(files, folder) if create_intermediate_files?

  unless skip_normal_animation?
    puts "Will convert #{files.size} frames to the default set of animations"
    create_animations_for_default_profiles(files, animation_prefix(safe_folder_prefix, 'normal'))
  end

  if create_back2front_animation?
    offset = files.size
    reverse_files = files[1...-1].reverse
    reverse_files = files if reverse_files.size == 0 and skip_normal_animation? # ensure we can create a reverse animation if required

    if reverse_files.size > 0
      reverse_files = create_intermediate_files(reverse_files, folder, offset) if create_intermediate_files?

      puts "Will convert #{files.size} files + #{reverse_files.size} reversed frames to the default set of back-to-front animations"
      create_animations_for_default_profiles(files + reverse_files, animation_prefix(safe_folder_prefix, 'back2front'))
    else
      puts "Animation has too little frames to require a back-to-front animation."
    end
  end  
end