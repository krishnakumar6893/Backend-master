class AppMailer < ActionMailer::Base
  include Resque::Mailer # sent mails async
  include AbstractController::Callbacks

  default_url_options[:host] = APP_HOST_URL
  default from: '"Fontli" <noreply@fontli.com>', return_path: '"Fontli" <noreply@fontli.com>'
  layout 'email', only: :send_email_campaign
  layout 'emailer', only: :send_wand_notification

  after_filter :set_delivery_options, only: :send_email_campaign

  def welcome_mail(user)
    @user = user
    mail(:to => user['email'], :subject => "Welcome to Fontli")
  end

  def forgot_pass_mail(params)
    @params = params
    mail(:to => params['email'], :subject => "Fontli: New password")
  end

  def feedback_mail(feedbk)
    @feedbk = feedbk
    @user = feedbk.user
    mail(:to => 'info@fontli.com',
         :subject => "Feedback API - #{Rails.env}: #{feedbk.sugg_type}")
  end

  def sos_requested_mail(sos_id)
    @user = Photo.find(sos_id).user
    to_users =  SECURE_TREE['admin_mail_receivers']
    mail(:to => to_users, :subject => "Fontli: New SoS requested")
  end

  def inactive_collection_creation_mail(collection_id)
    @collection = Collection.find(collection_id)
    to_users =  SECURE_TREE['admin_mail_receivers']
    mail(:to => to_users, :subject => "Fontli: New Collection")
  end

  def send_email_campaign(email)
    @user = User.where(email: email).first
    headers['List-Unsubscribe'] = "<#{unsubscribe_url(@user)}>" if @user
    mail(to: email, subject: "Why you should get back to Fontli?")
  end

  def approve_feed_mail(post_id)
    @user = Photo.find(post_id).user
    to_users =  SECURE_TREE['admin_mail_receivers']
    mail(:to => to_users, :subject => "Fontli: Approve Post")
  end

  def send_wand_notification(email)
    @user = User.where(email: email).first
    if @user
      headers['List-Unsubscribe'] = "<#{unsubscribe_url(@user)}>"
      mail(to: email, subject: "Have you tried the new feature from Fontli Labs?")
    end
  end

  private

  def set_delivery_options
    message.delivery_method(:smtp, SMTP_CONFIG['ses'])
  end
end
