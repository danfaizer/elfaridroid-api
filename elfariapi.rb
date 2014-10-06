require 'rubygems'
require 'yaml'
require 'sinatra'
require 'thin'
require 'logger'
require 'thread'
require 'socket'
require 'digest/md5'
load 'ircbot.rb'

## Load custom logger
begin
  $lh = "elFariAPI -"
  $logger = Logger.new(STDERR)
  $logger.level = Logger::INFO
  $logger.info "#{$lh} Logger initialized successfully"
rescue
  $logger.error "#{$lh} Logger initialization failed"
  raise 
end

## Load configuration file
begin
  $conf = YAML.load(File.open('./ircbot.yml'))
  $logger.info "#{$lh} Configuration properties loaded successfully"
rescue
  $logger.error "#{$lh} Configuration properties load failed"
  raise
end

def ircbot_socket(data)
  begin
    sock = TCPSocket.new $conf['socket_server'], $conf['socket_port']
	sock.write data
	sock.close
	return true
  rescue
    return false
  end
end

def check_passphrase(passphrase)
  	$logger.info "#{$lh} #{pp}"
  if passphrase == Digest::MD5.hexdigest($conf['passphrase'])
  	return true
  else
  	return false
  end
end
 
$ircbot = IRCBot.new

get '/status' do
  if ircbot_socket("PING#PING")
    status 200 # OK
    body ''
  else
  	status 503 # Internal error
    body '{ "ERROR": "Service unavailable" }'
  end
end
 
post '/send/:passphrase' do
  if check_passphrase(params[:passphrase])
    puts params[:data]
    status 202 # Accepted
    body ''
  else
  	status 401 # Unauthorized
  	body '{ "ERROR" : "Bad passphrase" }'
  end
end

ircbot_process = fork do
  $ircbot.start
end