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
    dst = []
    str.each{ |line|
      line.gsub!(/ *#.*/, '')
      next if line.strip==""    # space only
      dst << line
    }
    dst << "\n" # sentinel

    src = []
    5.times {
      break if src.size == dst.size
      src = dst; dst = []
      anchors = {}
      a0 = {}
      src.each_index{ |idx|
        next unless src[idx+1]
        line = src[idx]
        line =~ %r{^ *.*&(\w+)}; anc = $1
        idt = line.index(/[^ ]/)
        ndt = src[idx+1].index(/[^ ]/)
        a0[anc] = {:start=>idx+1, :indent=>idt} if anc    # anchor start
        a0.select{ |k, v| v[:indent]>=idt }.each{ |k, v|
          next if k==anc
          # anchor end
          a0.delete(k)
          anchors[k] = v.merge({:end=>idx-1})
        }
      }
      src.each_index{ |idx|
        line = src[idx]
        if line =~ %r{^ *(:?\w+:) *\*\|(\w+)} && anchors[$2]
          word = $1; anc = $2
          idt = " "*line.index(/[^ ]/)
          ndt = " "*src[idx+1].index(/[^ ]/)
          if idt >= ndt
            dst << "#{idt}#{word} *#{anc}\n"
          else
            dst << "#{idt}#{word}\n"
            a0 = anchors[anc]
            idt = src[a0[:start]].index(/[^ ]/)
            src[a0[:start]..a0[:end]].each{ |l|
              dst << ndt + ' '*(l.index(/[^ ]/) - idt) + l.lstrip
            }
          end
        else
          dst << line
        end
      }
    }
    dst.collect!{|line|
      line=~%r{^( *:?\w+:) *\*\|\w+} ? $1+"\n" : line
    }
    y = parser.load(dst.to_s)
  end
end
