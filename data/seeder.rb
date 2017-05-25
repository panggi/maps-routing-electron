require 'csv'
require 'json'
require 'faraday'

bandung = CSV.read("bandung_coord.csv");0

elastic = Faraday.new(:url => 'http://localhost:9200') do |faraday|
  faraday.request :url_encoded
  faraday.response :logger
  faraday.adapter Faraday.default_adapter
end

bandung.each do |node|
  elastic.put do |req|
    req.url "/bandung/location/#{node[0]}"
    req.headers['Content-Type'] = 'application/json'
    req.body = {pin: {location:{lat:node[2].to_f,lon:node[1].to_f}}}.to_json
  end
end
