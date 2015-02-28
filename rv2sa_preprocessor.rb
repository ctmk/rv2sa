=begin
=end

module Rv2sa; end

class Rv2sa::PreProcessor
  attr_reader :variables
  
  def initialize(variables = {}, &block)
    @buffer = []
    @variables = variables
    @indent_level = []
    @skip_level = nil
    @read_file = block
  end

  def process(script, file_name = "")
    script.each_line.with_index do |line, line_no|
    begin
      process_line(line)
      rescue StandardError, SyntaxError => e
        $stderr.puts "An Error has occured in '#{file_name}' l.#{line_no+1}\n #{e}"
        raise
      end
    end
    unless @indent_level.empty?
      mes = "Unexpected end-of-script, expecting #endif (nesting level.#{@indent_level.size})"
      $stderr.puts "An Error has occured in '#{file_name}'\n #{mes}"
      raise SyntaxError, mes
    end
    @buffer.join("\n")
  end

  def process_line(line)
    line.chomp!
    line.gsub!(/[A-Z:][A-Z0-9_]+/) {|md|
      k = md.intern
      @variables.has_key?(k) ? @variables[k] : md
    }
    if md = /^\s*#([a-z][\w\?\!]*)\s*([\w\W)]*)$/.match(line)
      process_command(md[1], md[2])
    else
      @buffer.push(line) unless @skip_level || line.empty?
    end
  end

  def process_command(cmd, args)
    raise SyntaxError, "Unknown command '##{cmd}'" unless cmd && Command.method_defined?(cmd = cmd.intern)

    begin
      args = eval("[#{args}]") || []
    rescue StandardError, SyntaxError => e
      raise SyntaxError, "Invalid arguments '(#{args})' for '##{cmd}', #{e}"
    end

    if @skip_level
      case cmd
      when :if, :ifdef, :ifndef, :else, :elif, :else_ifdef, :else_ifndef, :endif
      else
        return false
      end
    end

    begin
      send(cmd, *args)
    rescue ArgumentError => e
      raise SyntaxError, "#{cmd}(#{args}), #{e}"
    end

    return true
  end

  module Command
    def if(exp)
      @indent_level.push(true)
      if exp
        @indent_level[-1] = false
      else
        @skip_level ||= @indent_level.size
      end
      exp
    end
    
    def ifdef(*args)
      self.if(self.defined(*args))
    end

    def ifndef(name)
      self.if(self.defined(name).!)
    end

    def endif
      raise SyntaxError, "Unexpected #endif" if @indent_level.empty?
      @indent_level.pop
      if @skip_level && @indent_level.size < @skip_level
        @skip_level = nil
      end
    end
    
    def else_ifdef(*args)
      elif(self.defined(*args))
    end

    def else_ifndef(name)
      elif(self.defined(name).!)
    end

    def elif(exp)
      raise SyntaxError, "Unexpected #else_if" if @indent_level.empty?
      count = @indent_level.size
      if @skip_level == count
        if exp
          @skip_level = nil
          @indent_level[-1] = false
        end if @indent_level.last
      else
        @skip_level ||= count
      end
    end

    def else
      raise SyntaxError, "Unexpected #else" if @indent_level.empty?
      if @skip_level
        if @skip_level == @indent_level.size
          @skip_level = nil
          @indent_level[-1] = false
        end if @indent_level.last
      else
        @skip_level = @indent_level.size
      end
    end

    def include(filename)
      begin
        script = @read_file.call(filename)
        pp = Rv2sa::PreProcessor.new(@variables, &@read_file)
        @buffer.push pp.process(script, filename)
      rescue StandardError, SyntaxError => e
        raise SyntaxError, "Failed to include '#{filename}', #{e}"
      end
    end

    def define(name, value = true)
      @variables[name] = value
    end

    def defined(name, *args)
      if args.empty?
        @variables.has_key?(name)
      else
        @variables.has_key?(name) && @variables[name] == args[0]
      end
    end

    def defined_value(name)
      @variables[name]
    end

    def undefine(name)
      @variables.delete(name)
    end

    def warning(message)
      $stderr.puts "#warning #{message}"
    end

    def error(message)
      raise SyntaxError, "#error #{message}"
    end
  end
  include Command
end

