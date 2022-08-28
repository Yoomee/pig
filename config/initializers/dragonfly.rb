require 'dragonfly'
require 'dragonfly/s3_data_store'

# Configure
Dragonfly.app.configure do
  # ignore SHA as redactor doesn't seem to be inserting them correctly
  verify_urls false

  plugin :imagemagick

  secret '5c0fdd809b3682e9fbfc93b9d7fb4da7c839f9f4ad445ac022cc035fda0526ed'

  url_format "/media/:job/:name"
 
  puts ""
  puts "INFO: DragonFly is using S3_BUCKET_NAME: #{ENV['S3_BUCKET_NAME']}"
  puts ""

  datastore :s3,
    bucket_name: ENV['S3_BUCKET_NAME'],
    access_key_id: ENV['S3_ACCESS_KEY_ID'],
    secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
    region: ENV['S3_REGION'],
    url_scheme: 'https'


end

# Logger
Dragonfly.logger = Rails.logger

# Mount as middleware
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end
