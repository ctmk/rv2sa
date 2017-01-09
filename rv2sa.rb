#! ruby -Ku
# coding: utf-8

=begin
  Scripts.rvdata2の分解/結合を行う。
=end

Version = "2.3.3"
$ORIGINAL_LOAD_PATH = $LOAD_PATH.clone

require_relative "./rv2sa_converter"
require "optparse"

class String
	def unindent; gsub(/^\s{#{scan(/^\s*/).map(&:size).min}}/, ''); end
end

module Rv2sa
  Options = Struct.new("Options", :mode, :input, :output, :flags, :debuginfo, )
  class InvalidArgument < StandardError; end

  # @param [Array] argv
  def self.run(argv, stdout = $stdout)
    options = parse_arguments(argv)

    case options.mode
    when :compose
      Converter::Composition.convert(options.input, options.output, options.flags, options.debuginfo)
    when :decompose
      Converter::Decomposition.convert(options.input, options.output)
    end
  end

  # @param [Array] argv
  def self.parse_arguments(argv)
    options = Options.new(nil)
    optparser = OptionParser.new

    def optparser.error(msg = nil)
      warn msg if msg
      warn help()
      raise InvalidArgument
    end

    define_options(optparser, options)
    
    begin
      optparser.parse(argv)
    rescue OptionParser::ParseError => err
      optparser.error err.message
    end

    validate_options(optparser, options)

    options
  end

  def self.define_options(optparser, options)
    optparser.on("-c", "--compose=FILE", "Compose: specify a source file") do |val|
      options.input = val
      options.mode = :compose
    end
    
    optparser.on("-d", "--decompose=FILE", "Decompose: specify a source file") do |val|
      options.input = val
      options.mode = :decompose
    end
    
    optparser.on("-o", "--output=DIR|FILE", "destination file or directory") do |val|
      options.output = val
    end
    
    optparser.on("-f", "--flagss=FLAGS", "flags (it works on composing)") do |val|
      options.flags = val.split(/\s*,\s*/).map(&:intern)
    end

    optparser.on("-i", "--debuginfo", "to imply debug informations") do |val|
      options.debuginfo = true
    end
  end
  
  def self.validate_options(optparser, options)
    case options.mode
    when :compose
      if !options.output || File.directory?(options.output)
        optparser.error %Q("#{options.output} is specified as file but is directory")
      end
    when :decompose
      unless options.output && File.directory?(options.output)
        optparser.error %Q("#{options.output}" is not directory)
      end
    else
      optparser.error "specify -c or -d"
    end
    
    unless options.input && File.file?(options.input)
      optparser.error %Q("#{options.input}" is not found)
    end
    
  end
  
end


begin
  Rv2sa.run(ARGV)
rescue Rv2sa::InvalidArgument
  # The command-line arguments are invalid
  exit 1
end

