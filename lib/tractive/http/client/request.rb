# frozen_string_literal: true

module Http
  module Client
    class Request
      def initialize(args)
        @args = args
        @max_retries = args[:max_retries] || 3
      end

      def execute(&block)
        retries = 0

        begin
          retries += 1
          RestClient::Request.execute(@args, &block)
        rescue RestClient::Forbidden => e
          retry_after = e.http_headers[:x_ratelimit_reset].to_i - Time.now.to_i + 5
          raise e if retry_after.negative? || retries > @max_retries

          while retry_after.positive?
            minutes = retry_after / 60
            seconds = retry_after % 60

            $logger.info "Rate Limit Exceeded, Will retry in #{minutes} min #{seconds} sec"
            sleep(1)

            retry_after = e.http_headers[:x_ratelimit_reset].to_i - Time.now.to_i + 5
          end
          retry if retries <= @max_retries
        end
      end

      attr_reader :response

      class << self
        def get(url, headers = {}, &block)
          execute(method: :get, url: url, headers: headers, &block)
        end

        def post(url, payload, headers = {}, &block)
          execute(method: :post, url: url, payload: payload, headers: headers, &block)
        end

        def put(url, payload, headers = {}, &block)
          execute(method: :put, url: url, payload: payload, headers: headers, &block)
        end

        def patch(url, payload, headers = {}, &block)
          execute(method: :patch, url: url, payload: payload, headers: headers, &block)
        end

        def execute(args, &block)
          new(args).execute(&block)
        end
      end
    end
  end
end
