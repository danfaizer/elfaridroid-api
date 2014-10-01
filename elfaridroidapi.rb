require 'rubygems'
require "yaml"
require "sinatra"
require "thin"
require "logger"
 
get '/status' do
  status 200
  body ''
end
 
post '/send' do
  puts params[:data]
  status 202
  body ''
end