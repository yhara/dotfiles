require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 1000

require 'rubygems'
require 'wirble'
Wirble.init
Wirble.colorize

#require 'irb_rocket'

# --- truncate long output (load wirble first!)
#module IRB
#  class Irb
#    CUT = 1000
#    def output_value
#      if @context.inspect?
#        s = @context.last_value.inspect
#        if s.size > CUT
#          s = s.slice!(0, CUT) + "...(snipped)"
#        end
#        printf @context.return_format, Wirble::Colorize.colorize(s)
#      else
#        printf @context.return_format, @context.last_value
#      end
#    end
#  end
#end
#
