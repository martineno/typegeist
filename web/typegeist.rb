require "sinatra"

class Typegeist < Sinatra::Base
    get '/' do
        redirect "/stub.html"
    end
end