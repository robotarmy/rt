$:.push "."
require 'rt'
require 'yaml'
require 'stringio'
describe RT do

  describe "RT Defaults to" do
    let(:rt) do
      RT.new({})
    end
    it "$stdout for stdout with a new RT" do 
      rt.stdout.should == $stdout
    end
    it "prompt true with a new RT" do
      rt.prompt.should == true
    end
    it "$stdin for stdin with a new RT" do
      rt.stdin.should == $stdin
    end
  end
  describe "given a file" do
    let(:mock_filename) do

      f = File.open('mock_file.txt',File::CREAT|File::TRUNC|File::RDWR) do |f|
        f << %%line 1 foo\n%
        f << %%line 2 foplzo\n%
        f << %%line 3 "'foo'"^^oofoo--marm\n%
      end
      'mock_file.txt'
    end

    let(:rt) do 
      @search = /foo/
      @replace = "bar"
      re_list = { 
        @search => @replace,
      }
      rt = RT.new(re_list)
      rt.stdout = StringIO.new
      rt.prompt = true
      rt.get_prompt = 'y'
      rt
    end

    it "closes the file after the last line is evaluated" do 
      rt.current_filename = mock_filename
      3.times do
        rt.replacement_line 
      end
      debugger
      rt.current_file.closed?.should be_true
    end

    it "run a regular expression and prompt to execute replace" do 
      rt.current_filename = mock_filename
      rt.replacement_line.should include %%line 1 bar%
      rt.replacement_line.should include %%line 2 foplzo%
      rt.replacement_line.should include %%line 3 "'bar'"^^oobar--marm%
    end
    it "can run on the entire file and replace it" do
      rt.current_filename = mock_filename
      rt.run
    end
  
  end

  it "given a directory use each file for search and replace"
  describe "searching for foo and replacing with bar" do

    let(:rt) do 
      @search = /foo/
      @replace = "bar"
      re_list = { 
        @search => @replace,
      }
      rt = RT.new(re_list)
      # mock out stdout
      rt.stdout = StringIO.new
      # turn on prompt
      rt.prompt = true
      # set default prompt value for mock prompt
      rt.get_prompt = 'y'
      # set mock current line
      rt.current_line = "foo"
      # this will be the set value of 'rt' for this let
      rt
    end
    it "shows a prompt if prompt is true" do
     rt.replacement_line
     info = %%Replacing #{@search} with #{@replace}%
     prompt = %%Would you like to replace this instance : \[y\] or \[n\] ?%
     rt.stdout.string.should include(info)
     rt.stdout.string.should include(prompt)
    end

    it "can be configured to take a list of search and replace" do
      has_run_once = false
      rt.each_regexp do |s,r|
        has_run_once = true
        s.should == @search
        r.should == @replace
      end
      has_run_once.should be_true
    end

    it "should replace foo with bar" do
      rt.replacement_line.should == 'bar'
      rt.current_line = "aaaaafooaaaa"
      rt.replacement_line.should == 'aaaaabaraaaa'
    end

    it "the replacement should have quotes and apostrophes if intended" do
      rt.current_line = %%"Top 'o the foo morning, to ya, foo O'Malley!", he said.%
      rt.replacement_line = %%"Top 'o the bar morning, to ya, bar O'Malley!", he said.%
    end 
    describe "prompts to excute a replace" do
      before do
        rt.prompt = true
        rt.current_line = "foo"
      end
      it "does change replacement if yes\n" do
        rt.get_prompt = "yes\n"
        rt.replacement_line.should == 'bar'

        rt.get_prompt = "y\n"
        rt.replacement_line.should == 'bar'
      end
      it "does change replacement if yes" do
        rt.get_prompt = 'y'
        rt.replacement_line.should == 'bar'

        rt.get_prompt = 'Y'
        rt.replacement_line.should == 'bar'
      end
      it "does not change replacement if no" do
        rt.get_prompt = 'n'
        rt.replacement_line.should == 'foo'

        rt.get_prompt = 'N'
        rt.replacement_line.should == 'foo'
      end
    end
  end
    
end

