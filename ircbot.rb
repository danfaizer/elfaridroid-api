require 'rubygems'
require 'yaml'
require 'cinch'
require 'logger'
require 'socket'

## Load custom logger
begin
  $lh = "IRCBot -"
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

class IRCMessenger
  include Cinch::Plugin
  listen_to :monitor_msg, :method => :send_msg
  def send_msg(m, msg)
     Channel($conf['channels'].first).send "#{msg}"
  end
end

class IRCPing
  include Cinch::Plugin
  listen_to :ping_msg, :method => :send_msg
  def send_msg(m, msg)
     Channel($conf['nickname']).send "#{msg}"
  end
end
 
class IRCBot
  def initialize
    begin
      @bot = Cinch::Bot.new do
        configure do |c|
          c.server = $conf['server']
          c.channels = $conf['schannels']        
          c.nick = $conf['nickname']
          c.plugins.plugins = [IRCMessenger , IRCPing]
        end
      end
      $logger.info "#{$lh} Bot initialized successfully"
    rescue
      $logger.error "#{$lh} Bot initialization failed"
      raise
    end
  end

  def server(bot)
    begin
      $logger.info "#{$lh} Starting IRCMessenger socket at #{$conf['socket_server']}:#{$conf['socket_port']}"
      server = TCPServer.new $conf['socket_server'], $conf['socket_port']
      loop do
        Thread.start(server.accept) do |client|
          listener,message = client.gets.split('*',2)
          $logger.info "New socket message TYPE: #{listener} - MESSAGE: #{message}"
          case listener
            when 'PING'
              bot.handlers.dispatch(:ping_msg, nil, message)
            when 'MSG'
              bot.handlers.dispatch(:monitor_msg, nil, message) unless message.nil?
          end
          client.close
        end #Thread.Start
      end #loop
    rescue
      $logger.error "#{$lh} An error ocurred when trying to start IRCMessenger socket at #{$conf['socket_server']}:#{$conf['socket_port']}"
    end
  end

  def start
    begin
      Thread.new { server(@bot) }
      @bot.start
      $logger.info "#{$lh} Connected to #{$conf['server']} successfully"
      return true
    rescue
      $logger.error "#{$lh} Connection to #{$conf['server']} failed"
      raise
    end
  end

end