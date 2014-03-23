#! ruby -Ku
# coding: utf-8

=begin
Script.rvdata2を分解したり生成したりする
Author: Nobu
=end

Version = "1.3.0"

require "kconv"
require "optparse"
require "zlib"
require "find"

Options = Struct.new("Options", :rvfile, :compmode, :workdir, :linkorder)
$options = Options.new(nil)

#
# コマンドライン引数の処理
# 
def parseArguments()

  optparser = OptionParser.new
  
  optparser.on("-c", "--compress FILE", "assemble Script.rvdata2 from working directory") do |val|
    $options.rvfile = val
    $options.compmode = true
  end

  optparser.on("-d", "--decompress FILE", "dismantle Script.rvdata2 to working directory") do |val|
    $options.rvfile = val
    $options.compmode = false
  end

  optparser.on("-w", "--workdir DIR", "path to working directory") do |val|
    $options.workdir = val
  end

  optparser.on("-l", "--linkorder FILE", "output link-order to text file") do |val|
    $options.linkorder = val
  end

  begin
    optparser.parse(ARGV)

    unless $options.rvfile && ($options.compmode || File.exist?($options.rvfile)) then
      STDERR.print "Error!! rvdata2 file '#{$options.rvfile}' is not found\n"
      raise
    end

    unless $options.workdir && File.exist?($options.workdir) then
      STDERR.print "Error!! the working directory '#{$options.workdir}' is not found\n"
      raise
    end

    if $options.compmode && $options.linkorder && (! File.exist?($options.linkorder)) then
      STDERR.print "Error!! the file which specifies link order '#{$options.linkorder}' is not found\n"
      raise
    end

  rescue
    optparser.parse("--help")
  end

end

# 
# Script.rvdata2を読み込む
# 
def loadScriptData(filename)
  bin = File::binread(filename)
  data = Marshal.load(bin)
  return data
end

# 
# Script.rvdata2を書き出す
# 
def saveScriptData(filename, data)
  file = File.open(filename, "wb")
  Marshal.dump(data, file)
  file.close
end

# 
# Script.rvdata2の中身をパースしてばらばらのファイルに戻す
#
def decompress()
  data = loadScriptData($options.rvfile)

  if $options.linkorder
    linkorder = []
    for v in data do
      filepath = "#{$options.workdir}/#{v[1]}.rb"
      linkorder.push(v[1])
      File::binwrite(filepath, Zlib::Inflate.inflate(v[2]))
    end
    File::write($options.linkorder, linkorder.join("\n"))

  else
    i = 0
    for v in data do
      index = sprintf("%05d", i)
      filename = "#{$options.workdir}/#{v[1]}_#{index}_#{v[0]}.rb"
      File::binwrite(filename, Zlib::Inflate.inflate(v[2]))
      
      i += 1
    end
  end

end

#
# 指定したフォルダにあるファイルをScript.rvdata2にまとめる
#
def compress()
  entries = Array.new()

  filelist = []
  if $options.linkorder
    open($options.linkorder) do |file|
      file.each_with_index do |line, i|
        name = line.chomp
        filepath = "#{$options.workdir}/#{name}.rb"
        if File.exist?(filepath)
          filelist.push({ :name => name, :index => i, :id => i, :file => filepath, })
        else
          STDERR.print "'#{filepath}' is skipped because not found\n"
        end
      end
    end

  else
    i = 0
    Find.find($options.workdir) do |f|
      filename = File::basename(f, ".rb")
      if filename =~ /([\w\W]*)_([0-9]+)_([0-9]+)/ then
        filelist.push({ :name => $1.toutf8, :index => $2.to_i, :id => $3.to_i, :file => f, })
        i += 1
      end
    end

    filelist.sort! {|a, b|
      a[:index] <=> b[:index]
    }
  end

  filelist.each_with_index{|file,i|
    
      index = file[:index]
      id = file[:id]
      name = file[:name]
      bin = File::binread(file[:file])

      # 本当はidを参照すべきなのだろうが何でも大丈夫みたいなので通し番を振る
      entry = [i, name, Zlib::Deflate.deflate(bin)]

      entries.push(entry)
  }

  saveScriptData($options.rvfile, entries)

end

#
# Entry Point
#
def main()
  parseArguments

  if $options.compmode then
    compress
  else
    decompress
  end
end

main()
