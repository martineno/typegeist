require "json"
require "securerandom"
require "sinatra"

$workqueue = open("../assets/top1000.csv").read.split
$open_wus = {}

class SpiderApi < Sinatra::Base
	get '/' do
		'<html><head><title>spider API host</title></head><body></body></html>'
	end

	options '/work' do
		response.headers["Access-Control-Allow-Origin"] = "*"
		200
	end

    get '/work' do
    	response.headers["Access-Control-Allow-Origin"] = "*"

        # remove the front of the work queue and put it on the back
        domain = $workqueue.shift
        $workqueue.push(domain)

        # make the URI
        uri = URI::HTTP.build({ :host => domain })

        # make a WU for this domain
        wuid = SecureRandom.hex
        $open_wus[wuid] = uri

        # generate result
        result = { :uri => uri, :work_unit => wuid }
        JSON.dump(result)
    end

    post '/work' do
    	response.headers["Access-Control-Allow-Origin"] = "*"

    	p request.POST

    	work_unit = request.POST["work_unit"]
    	wuid = work_unit["wuid"]

    	open_wu = $open_wus[wuid].to_s

    	if open_wu then
    		puts "hey that's our old friend " + open_wu

    		if open_wu == work_unit["site"] then
    			puts "uri check passed"

    			$open_wus.delete(wuid)
    		end
    	else
    		puts "no clue where they got that"
    	end

    	200
    end
end