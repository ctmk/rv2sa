=begin
=end

require "zlib"
require_relative "./rv2sa_preprocessor"

module Rv2sa
module Converter
  class InvalidFormatedFile < StandardError; end
  DefinitionFile = "Scripts.conf.rb"
end
end

class Rv2sa::Converter::Composition
  extend Rv2sa::Converter
  class << self
    
    # @param [String] input filename
    # @param [String] output filename
    # @param [Array<Symbol>] flags
    # @param [Boolean] debuginfo
    def convert(input, output, flags, debuginfo)
      work = File.dirname(input) + "/"
      
      script = File.open(input) {|f| f.read }
      definition = Definition.new(flags, work)
      begin
        definition.instance_eval(script)
      rescue => e
        warn "#{e.class.to_s}: #{e.to_s}"
        raise InvalidFormatedFile
      end

      data = compose(definition, work, debuginfo)
      save(output, data)
    end

    # @return [Array] raw data for Scripts.rvdata2
    # @param [Definition]
    # @param [String] working_dir
    # @param [Boolean] debuginfo
    def compose(definition, working_dir = "", debuginfo)
      entries = []
      pp = Rv2sa::PreProcessor.new {|file|
        File::binread(working_dir + file + ".rb")
      }
      definition.flags.each {|flag| pp.define(flag, true) }

      if debuginfo
        lp = $ORIGINAL_LOAD_PATH.map {|v| "'#{v}'" }.join(",\n")
        entries << [0, "rv2sa_definition", Zlib::Deflate.deflate("$rv2sa_path = '#{working_dir}'\n$LOAD_PATH.concat [#{lp}]")]
      end

      definition.files.each.with_index(1) do |file, index|
        filename = working_dir + file + ".rb"
        unless File.exist?(filename)
          warn "#{filename} is not found"
          next
        end
        
        id = index
        name = file
        bin = pp.process(File::binread(filename), file)
        
        entries << [id, name, Zlib::Deflate.deflate(bin)] if bin
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
    attr_reader :work_dir

    def initialize(flags, work_dir)
      @work_dir = work_dir
      @imports = []
      @flags = flags || []
      @files = []
    end

    def current_path
      @imports.empty? ? "" : (@imports.join("/") + "/")
    end
    
    # ファイルの追加
    # @param [Array|String] filelist
    # @param [Array<Symbol>] flags
    def add(filelist, *flags)
      flags.flatten!
      return unless flags.empty? || flags.any?(&@flags.method(:include?))
      filelist = filelist.unindent.split("\n") if filelist.is_a?(String)

      path = current_path
      @files += filelist.collect {|file| path + file }
    end

    # 別のScripts.conf.rbから読み込む
    # @param [Array|String] filelist
    # @param [Array<Symbol>] flags
    def import(filelist, *flags)
      flags.flatten!
      return unless flags.empty? || flags.any?(&@flags.method(:include?))
      filelist = filelist.unindent.split("\n") if filelist.is_a?(String)

      path = @work_dir + current_path
      filelist.each do |file|
        filename = path + file + "/" + Rv2sa::Converter::DefinitionFile
        script = File.open(filename) {|f| f.read }
        @imports.push file
        self.instance_eval(script)
        @imports.pop
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

      File.open("#{output}/#{DefinitionFile}", "w") {|f|
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

