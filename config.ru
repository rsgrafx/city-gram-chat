require './chat_app.rb'

use Faye::RackAdapter, :mount => '/faye', :timeout => 25

run ChatApp