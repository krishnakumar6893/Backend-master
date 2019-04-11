Fontli is a web application that helps designers and Type enthusiasts to discover fonts and great Typography.
It also serves as a backend/webservice for the supporting mobile applications.

[![Code Climate](https://codeclimate.com/github/Imaginea/fontli/badges/gpa.svg)](https://codeclimate.com/github/Imaginea/fontli)


### Prerequisites:
- Ruby version         1.9.3 (i686-linux)
- RubyGems version     1.8.25
- Rails version        3.2.22.5
- Mongo version        2.6.4
- JavaScript Runtime   therubyracer (V8)
- Image Manipulation   ImageMagick

### Setup:
`bundle install`

### Startup:
`unicorn_rails -c config/unicorn.rb`

OR

`rails s`

### App Documentation:
Go to **http://localhost:3000/doc**

### Development:
- Make changes and git commit appropriately.
- `git pull origin master`
- `git push origin master`

### Deployment:
 - Set the `GITLAB_USERNAME` and `GITLAB_ACCESS_TOKEN` in .env file. These environment variables will be used to set repo_url in deploy.rb file.
 - `cap deploy`
 - The deployment will first execute a task: `cap deploy:update_repo_url` to update the repository url in ./repo/config of the deployment folder of server. This is required as we are using https url instead of ssh url of remote repository.
 - Run `rake mailer:restart_worker` for restart resque mailer worker.
### Start push notifications:

`./script/apn_sender --environment=development --cert-pass=1234 --verbose start`

OR

`./script/apn_sender --environment=production --cert-pass=1234 --verbose start`

### Start Mailer Daemon:
`QUEUE=mailer rake environment resque:work`

### Start Resque Web:
`RAILS_ENV=production resque-web -L config/initializers/resque.rb`

### Mail:
For testing mail functionality in development environment
- Run `gem install mailcatcher` then `mailcatcher` 
- Go to http://localhost:1080/
- Send mail through smtp://localhost:1025
