require 'dragonfly'
require 'dragonfly/s3_data_store'

# Configure
Dragonfly.app.configure do
  # ignore SHA as redactor doesn't seem to be inserting them correctly
  verify_urls false

  plugin :imagemagick

  secret '5c0fdd809b3682e9fbfc93b9d7fb4da7c839f9f4ad445ac022cc035fda0526ed'

  url_format "/media/:job/:name"

  if Rails.env.production?
    datastore :s3,
      bucket_name: ENV['S3_BUCKET_NAME'],
      access_key_id: ENV['S3_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      region: ENV['S3_REGION'],
      url_scheme: 'https'
  else
    datastore :file,
      root_path: Rails.root.join('data', 'dragonfly', Rails.env),
      server_root: Rails.root.join('public')
  end

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
