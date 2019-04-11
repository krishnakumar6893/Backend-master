require 'net/http'
require 'uri'

module DeeptypeUtil

  def self.communicate_deeptype_with(params)
    deeptype_url = deeptype_request_url(params)

    response = error = ""
    retries = 0
    begin
      url = URI.parse(deeptype_url)
      req = Net::HTTP::Get.new(url.to_s)
      response = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

    rescue => error
      error = error.message
      Rails.logger.info(error)

      sleep(DeepType.time_lapse_between_retry)

      retry if (retries += 1) < DeepType.retries_for_deep_type
    end

    # RESPONSE
    response_sanitize response, error
  end

  # request url for deep-type SLA
  def self.deeptype_request_url(options)
    "#{ENV['DEEP_TYPE_URL']}style_image_path=#{options[:style_image_path]}"\
    "&content_image_path=#{options[:content_image_path]}&" \
    "result_image_path=#{options[:result_image_path]}&"\
    "result_image_name=#{options[:result_image_name]}&"\
    "content_text=#{CGI.escape(options[:content_text].to_s)}&"\
    "env=#{Rails.env}"
  end

  def self.response_sanitize(response, error)
    resulted_response = {}

    if response.present?
      resulted_response["status"] = "Success"
      resulted_response["error"] = ""
      resulted_response["body"] = response.body
    else
      resulted_response["status"] = "Failure"
      resulted_response["error"] = error
      resulted_response["body"] = ""
    end
    return resulted_response.to_json
  end
end
