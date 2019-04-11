namespace :mailer do
  desc 'Restart resque mailer'
  task :restart_worker => :environment do
    system("kill -s QUIT `ps -ef | grep 'mailer' | grep -v grep | awk '{print $2}'`")
    ENV['QUEUE'] = 'mailer'
    ENV['BACKGROUND'] = '1'
    Rake::Task["resque:work"].invoke
  end
end
