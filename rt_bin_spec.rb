$:.push "."
require 'rt'
require 'yaml'
require 'stringio'

describe "RT Bin" do
 describe "binary mode" do
    before do
      %x{cp rt.rb fixture.rb}
      %x{rm fixture.rb.bak}
      %x{rm stdout.txt}
    end
    it " can executed " do
      pending
      %x{ruby ./rt.rb > stdout.txt}
      $?.exited?.should be_true
      $?.exitstatus.should == 1
      IO.read('stdout.txt').should include("./rt filename_to_replace [--no-prompt]\n RT will read from .snoopy for regular expression search and replacements\n")
    end

    it " backs up filename " do
      %x{ruby ./rt.rb fixture.rb --no-prompt}
      File.exists?('fixture.rb.bak')
    end
    it " alters the original file" do
      File.open('.snoopy',"w+") do |f|
        f << {
          /RT/ => 'Snoopy'
        }.to_yaml
      end
      %x{ruby ./rt.rb fixture.rb --no-prompt}
      # it changes the class name
      IO.read("fixture.rb").should_not include("RT")
      IO.read("fixture.rb").should include("Snoopy")
    end
  end
end
