class FakeColor
  def underline; end

  %w{ red green yellow blue }.each do |m|
    define_method(m){ }
  end
end

class VanillaText
  class << self
    def apply
      String.class_eval do
        def colored
          FakeColor.new
        end
          
        def unindent 
          gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
        end
      end

      %w{ status success problem sorry important underline }.each do |m|
        String.class_eval do
          define_method(m){ self }
        end
      end
    end
  end
end

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
