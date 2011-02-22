$:.push "."
require 'rt'
require 'yaml'
require 'stringio'

module RTHelper
  FIXTURE_DIR=File.join(File.dirname(__FILE__),'fixtures')
  def fixture_path(str)
    File.join(FIXTURE_DIR,str)
  end

  def setup_bin_test
    %x{cp rt.rb #{mock_ruby_path}}
    %x{rm #{fixture_path('fixture.rb.bak')}}
  end

  def mock_file
    "mock_file.txt"
  end

  def mock_ruby_path
    fixture_path('fixture.rb')
  end

  def read_mock_ruby
    IO.read(mock_ruby_path)
  end

  def create_mock_file
    path = fixture_path(mock_file)
    f = File.open(path,File::CREAT|File::TRUNC|File::RDWR) do |f|
      f << %%line 1 foo\n%
      f << %%line 2 foplzo\n%
      f << %%line 3 "'foo'"^^oofoo--marm\n%
    end
    path
  end
end

RSpec.configure do |config|
  config.include RTHelper
end
