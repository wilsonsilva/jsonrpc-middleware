require './app'
require 'rack/contrib'

use Rack::JSONBodyParser
use Jason::Middleware::Compliance

run App.new
