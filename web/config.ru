require "sinatra"
require "./typegeist"
require "./spiderapi"

map '/' do
    run Typegeist.new
end

map '/api' do
    run SpiderApi.new
end