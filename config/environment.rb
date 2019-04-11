# Load the rails application
require File.expand_path('../application', __FILE__)
# Load smtp setting used in environment files
SMTP_CONFIG = Fontli.load_erb_config('smtp_settings.yml')[Rails.env]
# Initialize the rails application
Fontli::Application.initialize!
