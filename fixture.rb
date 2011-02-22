#!/usr/bin/env ruby
require 'yaml'
class Snoopy
  attr_accessor :re_list, 
                :current_line, 
                :replacement_line, 
                :prompt, 
                :stdout, 
                :stdin,
                :current_file,
                :current_filename

  def initialize(re_list)
    self.re_list = re_list
    self.stdin = $stdin
    self.stdout = $stdout
    self.prompt = true
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
  
  def next_line
    unless current_file.closed? 
      unless current_file.eof?
       line  = current_file.readline
        if current_file.eof?
          current_file.close
        end
        line
      end
    else
      nil
    end
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
  def statistic_line 
    %%#{line_count} lines / #{change_count} changes / #{match_count} matches%
  end
  def each_regexp
    self.re_list.each do | s, r|
      yield s, r
    end
  end
  def run
    %x{cp #{self.current_filename} #{self.current_filename}.bak}
    File.open(self.current_filename+'.work',"w+") do |f|
      line =replacement_line
      while !line.nil?
        f << line
        line = replacement_line
      end
    end
    %x{cp #{current_filename}.work #{current_filename}}
    stdout << "#{statistic_line}\n"
  end
end
if $0 == __FILE__
  filename = ARGV.shift
  if filename 
    puts "Operating on #{filename}"
    rt = Snoopy.new(YAML::load(IO.read('./.snoopy')))
    rt.current_filename = filename
    rt.prompt = !("--no-prompt" == ARGV.shift)
    rt.run
  else
    puts "./rt filename_to_replace [--no-prompt]"
    puts "Snoopy will read from .snoopy for regular expression search and replacements"
  end

end
