require 'bundler/setup'

Bundler.require

require 'sinatra/base'
require 'json'
require 'sinatra/json'

class ChatApp < Sinatra::Base
  helpers Sinatra::JSON
  # city-gram-chat.herokuapp.com

  configure :development do
    REDIS = Redis.new
    use Rack::Cors do
      allow do
        origins 'ws://localhost:9292', 'ws://127.0.0.1:9292', 'ws://localhost:9393', 'ws://127.0.0.1:9393'
        resource '*'
      end
    end
  end

  configure :production do

    uri = URI.parse(ENV["REDISTOGO_URL"])
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

    use Rack::Cors do
      allow do
        origins 'ws://city-gram.herokuapp.com'
                # regular expressions can be used here
          resource '*'
        end
    end
  end

  set :redis, REDIS
  set(:watcher, Thread.new do
    redis = Redis.new
    Thread.current['sockets'] = []
    redis.subscribe 'chat_screen' do |on|
      on.message do |channel, message|
        Thread.current['sockets'].each do |s|
          s.send message
        end
      end
    end
  end)

  get '/' do
    content_type :json
    request.websocket do |ws|
      ws.onopen do
        ws.send( {'sender' => 'CityGram', message: 'Give a Shout Out!'}.to_json )
        settings.watcher['sockets'] << ws
      end

      ws.onmessage do |msg|
        settings.redis.publish 'chat_screen', msg
      end

      ws.onclose do
        warn("websocket closed")
        settings.watcher['sockets'].delete(ws)
        # settings.sockets.delete(ws)
      end
    end
  end

end
