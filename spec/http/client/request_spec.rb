# frozen_string_literal: true

RSpec.describe Http::Client::Request do
  context "#execute" do
    it "should call `RestClient::Request.execute`" do
      expect(RestClient::Request)
        .to receive(:execute)
        .with(method: :get)
        .exactly(1)
        .times

      Http::Client::Request.execute(method: :get)
    end

    it "should `retry` after request limit reset time when API Limit Exceed" do
      allow_any_instance_of(RestClient::Forbidden)
        .to receive(:http_headers)
        .and_return(x_ratelimit_reset: Time.now.to_i - 4)

      call_count = 0
      allow(RestClient::Request).to receive(:execute).exactly(2).times do
        call_count += 1
        call_count == 1 ? raise(RestClient::Forbidden) : { status: 200 }
      end

      retry_text = "Rate Limit Exceeded, Will retry in 0 min 1 sec"
      allow($logger).to receive(:info).with(retry_text)

      Http::Client::Request.execute(method: :get, max_retries: 1)

      expect($logger).to have_received(:info).with(retry_text).once
    end

    it "should `raise` exception if it occours after max retries" do
      allow_any_instance_of(RestClient::Forbidden)
        .to receive(:http_headers)
        .and_return(x_ratelimit_reset: Time.now.to_i + 1)

      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Forbidden)

      expect { Http::Client::Request.execute(method: :get, max_retries: 1) }
        .to raise_error(RestClient::Forbidden)
    end
  end
end
