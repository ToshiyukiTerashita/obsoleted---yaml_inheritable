require 'yaml'
require 'erb'

module YAML
  def self.load(str)
    if defined? YAML_EXTENSION_INHERITABLE_LOAD && YAML_EXTENSION_INHERITABLE_LOAD
      inheritable_load(str)
    else
      parser.load(str)
    end
  end

  def self.inheritable_load(str)
    src = []
    str.each{ |line|
      line.gsub!(/ +#.*/, '')
      next if line.strip==""    # space only
      src << line
    }
    src << "  " # sentinel
    anchors = {}
    a0 = {}
    src.each_index{ |idx|
      if src[idx] =~ %r{^( *).*&(\w+)}    # anchor start
        a0[$2] = {:start=>idx+1, :indent=>$1.length}
      elsif a0.size>0
        indent = src[idx].index(/[^ ]/)
        a0.select{ |k, v| v[:indent]>=indent }.each{ |k, v| # anchor end
          a0.delete(k)
          anchors[k] = v.merge({:end=>idx-1})
        }
      end
    }
    dst = []
    src.each_index{ |idx|
      line = src[idx]
      if line =~ %r{^( *)(\w+ *:) *\*\| *(\w+)} && anchors[$3]
        dst << $1+$2+"\n"
        a0 = anchors[$3]
        indent = " "*src[idx+1].index(/[^ ]/)
        src[a0[:start]..a0[:end]].each{ |l|
          dst << indent+l.lstrip
        }
      else
        dst << line
      end
    }
    y = parser.load(dst.to_s)
  end
end
