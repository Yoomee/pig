require "capybara/dsl"
require "capybara/poltergeist"
require 'benchmark'


total_time_taken = 0
pages_tested = 0
failures = []


namespace :pig do
  task getting_old_emails: :environment do
    Pig::ContentPackage.where(next_review: Time.zone.today)
      .group_by(&:requested_by)
      .each do |user, content_packages|
        Pig::ContentPackageMailer.getting_old(user, content_packages).deliver_now
      end
  end

  namespace :db do
    task seed: :environment do
      Pig::Engine.load_seed
    end
  end
end
