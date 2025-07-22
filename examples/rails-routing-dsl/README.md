# Rails JSON-RPC Routing DSL

Demonstrates using the Rails routing DSL extension to route JSON-RPC methods to different controller actions for a
smart home control system.

## Highlights

Uses the `jsonrpc` routing DSL to map JSON-RPC methods to Rails controller actions with clean, readable syntax:

```ruby
class App < Rails::Application
  # ...
  routes.append do
    jsonrpc '/' do
      # Handle batch requests with a dedicated controller
      batch to: 'batch#handle'

      method 'on', to: 'main#on'
      method 'off', to: 'main#off'

      namespace 'lights' do
        method 'on', to: 'lights#on'        # becomes lights.on
        method 'off', to: 'lights#off'      # becomes lights.off
      end

      namespace 'climate' do
        method 'on', to: 'climate#on'       # becomes climate.on
        method 'off', to: 'climate#off'     # becomes climate.off

        namespace 'fan' do
          method 'on', to: 'fan#on'         # becomes climate.fan.on
          method 'off', to: 'fan#off'       # becomes climate.fan.off
        end
      end
    end
  end
end

class MainController < ActionController::Base
  def on
    render jsonrpc: { device: 'main_system', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'main_system', status: 'off' }
  end
end

class LightsController < ActionController::Base
  def on
    render jsonrpc: { device: 'lights', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'lights', status: 'off' }
  end
end

class ClimateController < ActionController::Base
  def on
    render jsonrpc: { device: 'climate_system', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'climate_system', status: 'off' }
  end
end

class FanController < ActionController::Base
  def on
    render jsonrpc: { device: 'fan', status: 'on' }
  end

  def off
    render jsonrpc: { device: 'fan', status: 'off' }
  end
end

class BatchController < ActionController::Base
  def handle
    # Process each request in the batch and collect results
    results = jsonrpc_batch.process_each do |request_or_notification|
      case request_or_notification.method
      when 'on'
        { device: 'main_system', status: 'on' }
      when 'off'
        { device: 'main_system', status: 'off' }
      when 'lights.on'
        { device: 'lights', status: 'on' }
      when 'lights.off'
        { device: 'lights', status: 'off' }
      # ... handle other methods
      end
    end

    render jsonrpc: results
  end
end
```

## Running

```sh
bundle exec rackup
```

## API

The server implements smart home controls with these procedures:

**Root Methods:**
- `on` - Turn home automation system on
- `off` - Turn home automation system off

**Lights Namespace:**
- `lights.on` - Turn lights on
- `lights.off` - Turn lights off

**Climate Namespace:**
- `climate.on` - Turn climate system on
- `climate.off` - Turn climate system off

**Climate Fan Namespace:**
- `climate.fan.on` - Turn fan on
- `climate.fan.off` - Turn fan off

**Batch Processing:**
- Batch requests are automatically routed to the `BatchController#handle` action
- The controller uses `jsonrpc_batch.process_each` to handle each request in the batch
- Responses are collected and returned as an array

## Example Requests

Turn on the home automation system:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "on", "params": {}, "id": 1}'
```

Turn off the home automation system:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "off", "params": {}, "id": 2}'
```

Turn on lights:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "lights.on", "params": {}, "id": 3}'
```

Turn off the lights:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "lights.off", "params": {}, "id": 4}'
```

Turn on the climate system:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "climate.on", "params": {}, "id": 5}'
```

Turn off the climate system:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "climate.off", "params": {}, "id": 6}'
```

Turn on fan:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "climate.fan.on", "params": {}, "id": 7}'
```

Turn off fan:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "climate.fan.off", "params": {}, "id": 8}'
```

Batch request for evening routine:
```sh
curl -X POST http://localhost:9292 \
  -H "Content-Type: application/json" \
  -d '[
    {"jsonrpc": "2.0", "method": "off", "params": {}, "id": 9},
    {"jsonrpc": "2.0", "method": "lights.off", "params": {}, "id": 10},
    {"jsonrpc": "2.0", "method": "climate.off", "params": {}, "id": 11}
  ]'
```
