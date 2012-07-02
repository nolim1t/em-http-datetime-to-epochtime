# Convert date to timestamp (With Olsen Timezones) 
# List of timezones: http://en.wikipedia.org/wiki/List_of_tz_database_time_zones

# Input: tz and string
# Output: Epoch timestamp

# gem install em-http-server
# gem install eventmachine
# (Also neeeds active_support/all)
require 'eventmachine'
require 'em-http-server'
require 'cgi'
require 'active_support/all'

class HTTPHandler < EM::HttpServer::Server
  def process_http_request
    puts @http_query_string
    puts @http_request_uri

    response = EM::DelegatedHttpResponse.new(self)
    status = 400
    body = ''
    if @http_request_uri == "/convert" then
      if @http_query_string != nil
        parse_request = @http_query_string.split('&')
        tz = ''
        ds = ''
        if parse_request.length == 2
          parse_request.each {|param|
            kv_array = param.split('=')
            if kv_array[0] == 'tz'
              tz = CGI::unescape(kv_array[1])
            elsif kv_array[0] == 'string'
              ds = CGI::unescape(kv_array[1])
            end
          }
          status = 200
          begin
            Time.zone = tz
            body = Time.zone.parse(ds).to_i.to_s
          rescue
            status = 500
            body = '-1'
            puts "#{$!}"
          end
        else
          body = '-1'
        end
      else
        body = '-1'
      end
    elsif @http_request_uri == "/gethour"
      if @http_query_string != nil
        parse_request = @http_query_string.split('&')
        tz = ''
        ts = ''
        if parse_request.length == 2
          parse_request.each {|param|
            kv_array = param.split('=')
            if kv_array[0] == 'tz'
              tz = CGI::unescape(kv_array[1])
            elsif kv_array[0] == 'ts'
              ts = CGI::unescape(kv_array[1])
            end   
          }
          if tz != '' and ts != ''
            begin
              status = 200
              Time.zone = tz
              body = Time.zone.at(ts.to_i).hour
            rescue
              puts "Error happened: #{$!}"
              status = 500
              body = '-1'
            end
          else
            body = '-1'
          end
        else
          body = '-1'
        end
      else
        # No parameters for /gethour
        body = '-1'
      end
    else
      status= 404
      body = '-1'
    end
    response.status = status
    response.content_type 'text/plain'
    response.content = body
    response.send_response
  end
end

if ENV['PORT'] != nil
  port = ENV['PORT'].to_i
else
  port = 8088
end
EM::run do
  puts "Starting server on port " + port.to_s
  EM::start_server("0.0.0.0", port, HTTPHandler)
end
