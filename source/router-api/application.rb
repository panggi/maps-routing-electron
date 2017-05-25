require 'sinatra'
require 'mormon'
require 'faraday'
require 'json'
require 'bigdecimal'
require 'sinatra/cross_origin'

set :bind, '0.0.0.0'
set :server, :puma
set :port, 4567

configure do
    enable :cross_origin
end

set :allow_origin, :any
set :allow_methods, [:get, :post, :options]
set :allow_credentials, true
set :max_age, "1728000"
set :expose_headers, ['Content-Type']

osm_loader = Mormon::OSM::Loader.new "../../data/bandung_indonesia.osm", :cache => true
osm_router = Mormon::OSM::Router.new osm_loader

elastic = Faraday.new(:url => "http://localhost:9200") do |faraday|
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end

options '/router' do
    cross_origin
end

post '/router' do
  erb :router
  content_type :json
  parsed = JSON.parse(request.body.read)
  get_route = osm_router.find_route parsed["start"].to_i, parsed["destination"].to_i, :cycle

  @route_result = {:status => "success", :data => get_route[1]}.to_json
end

options '/pointer' do
    cross_origin
end

post '/pointer' do
  erb :pointer
  content_type :json
  parsed = JSON.parse(request.body.read)

  pointer = elastic.post do |req|
    req.body = {"query":{"bool":{"must":{"match_all":{}},"filter":{"geo_distance":{"distance":parsed["distance"],"pin.location":{"lat":parsed["lat"],"lon":parsed["lon"]}}}}}}.to_json
    req.url "/bandung/location/_search"
    req.headers['Content-Type'] = 'application/json'
  end

  @pointer = {status: "success", data: JSON.parse(pointer.body)}.to_json
end
