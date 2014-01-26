class ColoredText
  class << self 
    def apply
      String.class_eval do
        require 'smart_colored'

        def unindent 
          gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
        end

        def status
          self.colored.yellow
        end

        def success
          self.colored.green.bold
        end

        def problem
          self.colored.yellow_on_red_bold
        end

        def sorry
          self.colored.red.bold
        end

        def important
          self.colored.magenta
        end
      end
    end
  end
end
