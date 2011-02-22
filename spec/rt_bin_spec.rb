require File.join(File.dirname(__FILE__),'spec_helper')

describe "RT Bin" do
 describe "binary mode" do
    before do
      setup_bin_test
    end

    it " backs up filename " do
      %x{ruby ./rt.rb #{mock_ruby_path} --no-prompt}
      File.exists?(fixture_path('fixture.rb.bak')).should be_true
    end

    it " alters the original file" do
      File.open('.snoopy',"w+") do |f|
        f << {
          /RT/ => 'Snoopy'
        }.to_yaml
      end
      %x{ruby ./rt.rb #{mock_ruby_path} --no-prompt}
      # it changes the class name
      read_mock_ruby.should_not include("RT")
      read_mock_ruby.should include("Snoopy")
    end
  end
end
