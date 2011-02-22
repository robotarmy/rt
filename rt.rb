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
      each_regexp do |s,r|
        unless @replacement_line.scan(s).empty?
          puts @replacement_line
          print_prompt_for(s,r)
          if yes?
            @replacement_line.gsub!(s,r)
          end
        end
      end
    end
    @replacement_line
  end
  def print_prompt_for(search,replace)
    stdout << "Replacing #{search} with #{replace}\n"
    stdout << "Would you like to replace this instance : [y] or [n] ?"
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
  end
end
if $0 == __FILE__
  filename = ARGV.shift
  if filename 
    puts "Operating on #{filename}"
    rt = RT.new(YAML::load(IO.read('./.snoopy')))
    rt.current_filename = filename
    rt.prompt = !("--no-prompt" == ARGV.shift)
    rt.run
  else
    puts "./rt filename_to_replace [--no-prompt]"
    puts "RT will read from .snoopy for regular expression search and replacements"
  end

end
