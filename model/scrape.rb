require "sequel"

class Scrape < Sequel::Model
    attr_accessor :status
    attr_accessor :uri
    attr_accessor :time_accessed

    one_to_many :styles
end

class Style < Sequel::Model
    attr_accessor :font_family
    attr_accessor :font_size
    attr_accessor :font_style
    attr_accessor :font_variant
    attr_accessor :font_weight

    attr_accessor :characters
    attr_accessor :elements
end