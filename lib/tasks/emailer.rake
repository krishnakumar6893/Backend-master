namespace :emailer do
  desc 'Send Wand notification'
  task :send_wand_notification => :environment do
    user_ids = ApiSession.where(:expires_at.gt => 6.months.ago).pluck(:user_id).uniq
    user_ids += SocialLogin.where(:logged_at.gt => 6.months.ago).pluck(:user_id).uniq
    user_ids = user_ids.uniq

    User.where(:id.in => user_ids).each do |user|
      AppMailer.send_wand_notification(user.email).deliver
    end
  end
end
