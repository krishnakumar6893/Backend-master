class EmailController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :set_current_controller
  skip_before_filter :verify_authenticity_token

  def bounce
    amz_message_type = request.headers['x-amz-sns-message-type']
    amz_sns_topic = request.headers['x-amz-sns-topic-arn']

    if amz_message_type.to_s.downcase == 'subscriptionconfirmation'
      send_subscription_confirmation request.raw_post
      return
    end

    if amz_message_type.to_s.downcase == 'notification'
      require 'json'
      json = JSON.parse(request.raw_post)
      message = JSON.load(json['Message'])
      type = message['notificationType']

      if type=='Bounce'
        message['bounce']['bouncedRecipients'].each do |recipient|
          EmailAddress.where(address: recipient['emailAddress'], status: type).first_or_create
        end
      end
    end
    render nothing: true
  end

  def itunes
    render layout: false
  end

  private

  def send_subscription_confirmation(request_body)
    require 'json'
    json = JSON.parse(request_body)
    subscribe_url = json ['SubscribeURL']
    require 'open-uri'
    open(subscribe_url)
  end
end
