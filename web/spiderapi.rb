require "sinatra"
require "json"

$workqueue = open("../assets/top1000.csv").read.split

class SpiderApi < Sinatra::Base
    get '/work' do
        # remove the front of the work queue and put it on the back
        domain = $workqueue.shift
        $workqueue.push(domain)

        # generate result
        result = { :uri => URI::HTTP.build({ :host => domain }) }
        JSON.dump(result)
    end
end