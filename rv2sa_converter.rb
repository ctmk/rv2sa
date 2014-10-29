=begin
=end

require "zlib"

module Rv2sa
module Converter
  class InvalidFormatedFile < StandardError; end

end
end

class Rv2sa::Converter::Composition
  extend Rv2sa::Converter
  class << self
    
    # @param [String] input filename
    # @param [String] output filename
    # @param [Array<Symbol>] flags
    def convert(input, output, flags)
      work = File.dirname(input) + "/"
      
      script = File.open(input).read
      definition = Definition.new(flags)
      begin
        definition.instance_eval(script)
      rescue => e
        warn "#{e.class.to_s}: #{e.to_s}"
        raise InvalidFormatedFile
      end

      data = compose(definition.files, work)
      save(output, data)
    end

    # @return [Array] raw data for Scripts.rvdata2
    # @param [Array<String>] files to compose
    # @param [String] working_dir
    def compose(files, working_dir = "")
      entries = []
      
      files.each_with_index do |file, index|
        filename = working_dir + file + ".rb"
        unless File.exist?(filename)
          warn "#{filename} is not found"
          next
        end
        
        id = index
        name = file
        bin = File::binread(filename)
        
        entries << [id, name, Zlib::Deflate.deflate(bin)]
      end

      entries
    end

    # @param [String] filename
    # @param [Object] data
    def save(filename, data)
      File.open(filename, "wb") {|f|
        Marshal.dump(data, f)
      }
    end

  end

  # .conf.rb でファイル定義を行う環境
  class Definition
    attr_reader :flags
    attr_reader :files

    def initialize(flags)
      @flags = flags || []
      @files = []
    end
    
    # ファイルの追加
    # @param [Array|String] filelist
    # @param [Array<Symbol>] flags
    def add(filelist, flags = [])
      flags = [flags].flatten
      return unless flags.empty? || flags.any?(&@flags.method(:include?))
      case filelist
      when String
        @files += filelist.unindent.split("\n")
      else
        @files += [filelist].flatten
      end
    end
  end

end

class Rv2sa::Converter::Decomposition
  extend Rv2sa::Converter
  class << self

    # @param [String] input filename
    # @param [String] output filenam
    def convert(input, output)
      begin
        data = load_data(input)
      rescue
        raise InvalidFormatedFile
      end
      save(output, data)
    end

    # @param [Array<Array>] entries
    def save(output, entries)
      entries.each do |entry|
        filename = "#{output}/#{entry[1]}.rb"
        filepath = File.dirname(filename)
        Dir.mkdir(filepath) unless Dir.exist?(filepath)
        File.binwrite(filename, Zlib::Inflate.inflate(entry[2]))
      end

      File.open("#{output}/Scripts.conf.rb", "w") {|f|
        f.puts %Q(add <<-EOS)
        entries.each do |entry|
          f.puts %Q(  #{entry[1]})
        end
        f.puts %Q(EOS)
      }
    end

    # @return [Array<Array>] raw data of Scripts.rvdata2
    # @param [String] filename
    def load_data(filename)
      File.open(filename, "rb") {|f|
        Marshal.load(f)
      }
    end

  end
end

