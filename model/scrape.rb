require "sequel"

def init_model
    DB.create_table? :scrapes do
        primary_key :id

        column :status, :integer
        column :uri, :string
        column :time_accessed, :datetime
    end

    DB.create_table? :styles do
        primary_key :id

        column :font_family, :string
        column :font_size, :string
        column :font_style, :string
        column :font_variant, :string
        column :font_weight, :string

        column :characters, :bignum
        column :elements, :bignum

        foreign_key :scrape_id, :scrapes
    end
end

init_model

class Scrape < Sequel::Model
    one_to_many :styles
end

class Style < Sequel::Model
end