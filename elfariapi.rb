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

class String
  def initial
    self[0,1]
  end
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
  if passphrase == Digest::MD5.hexdigest($conf['passphrase'])
  	return true
  else
  	return false
  end
end

def sanitize(message)
  if message.initial == '#' or
     message.initial == '/' or
     message.initial == '*'
     sanitize(message[1..-1])
  else
    return message
  end
end
 
$ircbot = IRCBot.new

get '/' do
  status 200 # OK
  body '{ "STATUS": "OK" }'
end

get '/status' do
  if ircbot_socket("PING*PING")
    status 200 # OK
    body ''
  else
  	status 503 # Service Unavailable
    body '{ "ERROR": "Service unavailable" }'
  end
end
 
post '/send/:user/:passphrase' do
  begin
    if check_passphrase(params[:passphrase])
      $logger.info "New message from #{params[:user]} : #{params[:data]}"
      if not params[:data].nil?
        message = sanitize(params[:data])
        ircbot_socket("MSG*#{params[:user]} dice:")
        sleep(2)
        if ircbot_socket("MSG*#{message}")
          status 202 # Accepted
          body ''
        else
          status 503 # Service Unavailable
          body ''
        end
      else
        status 204 # Empty
        body ''
      end
    else
      $logger.error "Wrong passphrase from #{params[:user]}"
    	status 401 # Unauthorized
    	body '{ "ERROR" : "Bad passphrase" }'
    end
  rescue => e
    $logger.error "ERROR: #{e}"
    status 503 # Unauthorized
    body '{ "ERROR" : "Something really ugly happened" }'
  end
end

ircbot_process = fork do
  $ircbot.start
end