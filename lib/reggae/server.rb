module Reggae

  class Server < EM::Connection

    include EM::HttpServer

    def initialize host, port
      @host, @port = host, port
    end

    def post_init
      super
      no_environment_strings
      @start_time = Time.now
      @header_processing = true
    end

    def request_fingerprint
      puts [@signature, @http_protocol, @http_request_method,
        @http_path_info, @http_request_uri].join " "
    end

    def set_client_headers
      @client_headers = Hash[*@http_headers.split("\x00").map do |h|
        h.split(/:\s+/,2)
      end.flatten]
    end

    def send_server_headers
      # see:    evma_httpserver/response.rb
      {
        'icy-notice1'   => 'reggae',
        'icy-notice2'   => 'reggae server',
        'icy-name'      => "reggae on #{@host}",
        'icy-genre'     => 'pfunk',
        'icy-url'       => "http://#{@host}:#{@port}",
        'icy-pub'       => false,
        'icy-metaint'   => 0
      }.each { |h,v| @response.headers[h] = v}
      @response.content_type 'audio/x-mpegurl'
      @response.status = 200    # setting status implicitly calls send_header
      @response.send_headers   # <-- won't work
      exit
    end

    def process_http_request
      request_fingerprint
      exit(-1) if @http_request_uri != '/'
      @response = EM::DelegatedHttpResponse.new self
      set_client_headers
      send_server_headers

      case @http_request_method.upcase
        when 'GET' then
          Reggae::Streamer.new self
        when 'POST' then
          puts 'got a post'
      end
    end

    def unbind
      puts "disconnected"
    end

  end
end
