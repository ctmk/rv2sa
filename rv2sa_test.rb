#! ruby -Ku
# coding: utf-8

=begin
  rv2saのテストを実行する
=end

require "test/unit"
require "fileutils"
require "find"

$VERBOSE = nil
begin
  require_relative "./rv2sa"
rescue SystemExit
end

class Rv2sa::Test < Test::Unit::TestCase
  NULL = Object.new
  def NULL.write(s); s.length; end
  
  def setup
  end
  
  def teardown
  end

  def test_argv
    FileUtils.mkdir('testdata/output') unless File.directory?('testdata/output')

    # No options
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run([]) }
 
    # No file specifying
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-c']) }
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-d']) }
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-o']) }

    # Specified a file but output is not specified
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-d', 'testdata/Scripts.rvdata2']) }
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-c', 'testdata/sample/Scripts.conf.rb']) }

    # Specified a directory but output does not exist
    assert_raise(Rv2sa::InvalidArgument) { Rv2sa.run(['-d', 'testdata/Scripts.rvdata2', '-o', 'none']) }
  end

  def test_converting
    FileUtils.remove_dir('testdata/output')
    FileUtils.mkdir('testdata/output')

    assert_nothing_raised() { Rv2sa.run(['-c', 'testdata/sample/Scripts.conf.rb', '-o', 'testdata/output/output.rvdata2']) }
    assert_nothing_raised() { Rv2sa.run(['-d', 'testdata/output/output.rvdata2', '-o', 'testdata/output']) }

    samples = Dir.chdir("testdata/sample") {
      Dir.glob("**/*.rb")
    }
    outputs = Dir.chdir("testdata/output") {
      Dir.glob("**/*.rb")
    }
    assert(samples == outputs, "#{samples.inspect} #{outputs.inspect}")

    samples.each do |name|
      assert(FileUtils.cmp("testdata/output/#{name}", "testdata/sample/#{name}"), "not matched #{name}")
    end
  end

  def test_converting_invalid_data
    assert_raise(Rv2sa::Converter::InvalidFormatedFile) {
      Rv2sa.run(['-c', 'testdata/invalid.dat', '-o', 'testdata/invalid_output.rvdata2'])
    }

    assert_raise(Rv2sa::Converter::InvalidFormatedFile) {
      Rv2sa.run(['-d', 'testdata/invalid.dat', '-o', 'testdata/output'])
    }
  end

end

