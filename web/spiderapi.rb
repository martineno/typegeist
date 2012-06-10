require "date"
require "json"
require "securerandom"
require "sinatra"
require "sequel"

$workqueue = open("../assets/top1000.csv").read.split
$open_wus = {}

DB = Sequel.connect("sqlite://test.db")
require "../model/scrape"
init_model

Statuses = { "success" => 1, "failed" => 0 }

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

        if domain.nil? then
            400
        end

        #$workqueue.push(domain)

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

                retrievedOn = work_unit["retrievedOn"].nil? ? DateTime.now : DateTime.parse(work_unit["retrievedOn"])

                scrape = Scrape.create(:status => Statuses[work_unit["status"]],
                                       :uri => work_unit["site"],
                                       :time_accessed => retrievedOn)

                if work_unit["styleDigest"] then
                    work_unit["styleDigest"].values.each do |style|
                        style = Style.create(:font_family => style["font-family"],
                                             :font_size => style["font-size"],
                                             :font_style => style["font-style"],
                                             :font_variant => style["font-variant"],
                                             :font_weight => style["font-weight"],
                                             :characters => style["characters"],
                                             :elements => style["elements"])

                        scrape.add_style(style)
                    end
                end

    			$open_wus.delete(wuid)
    		end
    	else
    		puts "no clue where they got that"
    	end

    	200
    end
end