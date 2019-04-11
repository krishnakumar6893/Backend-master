require 'ruby-progressbar'
namespace :users do
  desc "Update users photos_count"
  task :update_photos_count => :environment do
    progressbar = ProgressBar.create format: "%a %e %P% Processed: %c from %C"
    progressbar.total = User.non_admins.count
    User.non_admins.includes(:photos).all.each do |u|
      u.update_attribute(:photos_count, u.photos.count)
      progressbar.increment
    end
  end

  desc "Reset likes_count of all users"
  task :reset_likes_count => :environment do
    progressbar = ProgressBar.create format: "%a %e %P% Processed: %c from %C"
    progressbar.total = User.non_admins.count

    User.non_admins.includes(:likes).all.each do |user|
      next if user.likes_count == user.likes.count
      User.reset_counters(user.id, :likes)
      progressbar.increment
    end    
  end

  desc "Reset photos_count of all users"
  task :reset_photos_count => :environment do
    progressbar = ProgressBar.create format: "%a %e %P% Processed: %c from %C"
    progressbar.total = User.non_admins.count

    User.non_admins.includes(:photos).all.each do |user|
      next if user.photos_count == user.photos.count
      User.reset_counters(user.id, :photos)
      progressbar.increment
    end    
  end

  desc "Create user social logins"
  task :create_social_logins => :environment do
    progressbar = ProgressBar.create format: "%a %e %P% Processed: %c from %C"
    progressbar.total = User.where(:extuid.ne => nil).count
    User.where(:extuid.ne => nil).all.each do |u|
      u.social_logins.where(platform: u.platform, extuid: u.extuid).first_or_create
      progressbar.increment
    end
  end
end
