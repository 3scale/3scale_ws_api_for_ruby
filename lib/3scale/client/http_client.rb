require 'forwardable'

module ThreeScale
  class Client
    class HTTPClient
      extend Forwardable
      def_delegators :@http, :get, :post, :use_ssl?, :active?

      def initialize(options)

        @secure = !!options[:secure]
        @host = options.fetch(:host)
        @persistent = options[:persistent]

        backend_class = @persistent ? Persistent : NetHttp

        @http = backend_class.new(@host)
        @http.ssl! if @secure
      end

      class Persistent
        def initialize(host)
          require 'net/http/persistent'
          @http = ::Net::HTTP::Persistent.new
          @host = host
          @protocol = 'http'
        end

        def ssl!
          @protocol = 'https'
        end

        def get(path)
          uri = full_uri(path)
          get = Net::HTTP::Get.new(uri.request_uri)
          @http.request(uri, get)
        end


        def post(path, payload)
          uri = full_uri(path)
          post = Net::HTTP::Post.new uri.path
          post.set_form_data(payload)

          @http.request(uri, post)
        end

        def full_uri(path)
          URI.join "#{@protocol}://#{@host}", path
        end

      end

      class NetHttp
        extend Forwardable
        def_delegators :@http, :get, :post, :use_ssl?, :active?

        def initialize(host)
          @host = host
          @http = Net::HTTP.new(@host, 80)
        end

        def ssl!
          @http = Net::HTTP.new(@host, 443)
          @http.use_ssl = true
        end

        def post(path, payload)
          @http.post(path, URI.encode_www_form(payload))
        end
      end
    end
  end
end