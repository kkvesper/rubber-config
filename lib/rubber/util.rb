module Rubber
  module Util

    def parse_aliases(instance_aliases)
      aliases = []
      alias_patterns = instance_aliases.to_s.strip.split(/\s*,\s*/)
      alias_patterns.each do |a|
        if a =~ /~/
          range = a.split(/\s*~\s*/)
          range_items = (range.first..range.last).to_a
          raise "Invalid range, '#{a}', sequence generated no items" if range_items.size == 0
          aliases.concat(range_items)
        else
          aliases << a
        end
      end
      return aliases
    end

    # Opens the file for writing by root
    def sudo_open(path, perms, &block)
      open("|sudo tee #{path} > /dev/null", perms, &block)
    end

    def is_rails?
      File.exist?(File.join(Rubber.root, 'config', 'boot.rb'))
    end

    def is_bundler?
      File.exist?(File.join(Rubber.root, 'Gemfile'))
    end

    def has_asset_pipeline?
      is_rails? && Dir["#{Rubber.root}/*/assets"].size > 0
    end

    def prompt(name, desc, required=false, default=nil)
      value = ENV.delete(name)
      msg = "#{desc}"
      msg << " [#{default}]" if default
      msg << ": "
      unless value
        print msg
        value = gets
      end
      value = value.size == 0 ? default : value
      fatal "#{name} is required, pass using environment or enter at prompt" if required && ! value
      return value
    end

    def fatal(msg, code=1)
      puts msg
      exit code
    end

    # remove leading whitespace from "here" strings so they look good in code
    # skips empty lines
    def clean_indent(str)
      str.lines.collect do |line|
        if line =~ /\S/ # line has at least one non-whitespace character
          line.lstrip
        else
          line
        end
      end.join()
    end

    def is_instance_id?(str)
      str =~ /^i-[a-z0-9]+$/
    end

    def is_internet_gateway_id?(str)
      str =~ /^igw-[a-z0-9]+$/
    end

    extend self
  end
end
