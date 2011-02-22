#!/usr/bin/env ruby
require 'yaml'
class RT
  attr_accessor :re_list, 
                :current_line, 
                :replacement_line, 
                :prompt, 
                :stdout, 
                :stdin,
                :current_file,
                :current_filename,
                :directory

  def initialize(re_list)
    self.re_list = re_list
    self.stdin = $stdin
    self.stdout = $stdout
    self.prompt = true
  end


  def next_file_in_directory
    @files ||= Dir[%%#{self.directory}/**/*%].delete_if {|dir| File.directory?(dir)}
    next_file = @files.shift
    if next_file
      self.current_file = File.open(next_file,'r')
      self.current_filename = next_file
    else
      nil
    end
  end

  def current_filename=(filename)
    @current_filename = filename
    self.current_file = File.open(filename,'r')
  end

  def current_line
    # @current_line is only for 
    # setting in the mock context for testing
    @current_line || next_line
  end
 
  
  def file_open
    !self.current_file.closed? 
  end
  def file_not_finished
    !file_finished
  end
  def file_finished
    self.current_file.eof?
  end
  def finalize_file
    self.current_file.close
    inc_file_count
  end

  def next_line
    line = nil
    if file_open && file_not_finished
      line = self.current_file.readline
    end

    if file_open && file_finished
      finalize_file
    end
    line
  end

  def replacement_line
    @replacement_line = current_line
    unless @replacement_line.nil?
      inc_line_count
      each_regexp do |s,r|
        unless @replacement_line.scan(s).empty?
          inc_match_count
          print_prompt_for(@replacement_line,s,r)
          if yes?
            @replacement_line.gsub!(s,r)
            inc_change_count
          end
        end
      end
    end
    @replacement_line
  end
  def print_prompt_for(line,search,replace)
    stdout << "- #{line}"
    stdout << "+ #{line.gsub(search,replace)}"
    stdout << "Would you like to replace this instance : [y] or [n] ? "
  end

  def get_prompt=(p)
    @get_prompt = p
  end
  
  def get_prompt
    @get_prompt || stdin.gets
  end

  def yes?
    return true if prompt.nil? || !prompt
    return case get_prompt.chomp.downcase
    when 'yes' then
      true
    when 'y' then
      true
    else
      false
    end
  end 
  def inc_change_count
    @change_count = change_count.succ
  end
  def change_count
    @change_count ||= 0
  end
  def inc_match_count
    @match_count = match_count.succ
  end
  def match_count
    @match_count ||= 0
  end
  def inc_line_count
    @line_count = line_count.succ
  end
  def line_count
    @line_count ||= 0
  end
  def inc_file_count
    @file_count = file_count.succ 
  end
  def file_count
    @file_count ||=0
  end
  def statistic_line 
    %%#{line_count} lines / #{change_count} changes / #{match_count} matches / #{file_count} files%
  end
  def each_regexp
    self.re_list.each do | s, r|
      yield s, r
    end
  end
  
 
  def run_for_current_filename
    %x{cp #{self.current_filename} #{self.current_filename}.bak}
    File.open(self.current_filename+'.work',"w+") do |f|
      line = self.replacement_line
      while !line.nil?
        f << line
        line = self.replacement_line
      end
    end
    %x{cp #{current_filename}.work #{current_filename}}
    stdout << "#{statistic_line}\n"
  end

  def run
    if self.directory
      while next_file_in_directory 
        run_for_current_filename
      end
    else
      run_for_current_filename
    end
  end

  public
  def run_on(file_or_dir)
    if File.directory?(file_or_dir)
      self.directory = file_or_dir
    else
      self.current_filename = file_or_dir
    end
    self.run
  end
end
if $0 == __FILE__
  filename = ARGV.shift
  if filename 
    puts "Operating on #{filename}"
    rt = RT.new(YAML::load(IO.read('./.snoopy')))
    rt.prompt = !("--no-prompt" == ARGV.shift)
    rt.run_on(filename)
  else
    puts "./rt filename_to_replace [--no-prompt]"
    puts "RT will read from .snoopy for regular expression search and replacements"
  end

end
