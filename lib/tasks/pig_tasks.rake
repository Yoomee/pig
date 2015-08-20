 require "capybara/dsl"
require "capybara/poltergeist"
require 'benchmark'

total_time_taken = 0
pages_tested = 0
failures = []


class Screenshot
  include Capybara::DSL

  # Captures a screenshot of +url+ saving it to +path+.
  def capture(url, path)
    visit url
    return page.driver.status_code == 200 && !page.body.include?('Pig::')
  end
end

namespace :pig do
  task smoke: :environment do
    Capybara.run_server = false
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end
    Capybara.current_driver = :poltergeist

    links_to_test = Pig::Permalink.active
    links_to_test.each do |permalink|
      next if permalink.resource.nil? || permalink.resource.viewless?
      pages_tested += 1
      screenshot = Screenshot.new
      success = false
      time_taken = Benchmark.realtime do
        success = screenshot.capture "http://0.0.0.0:3000#{permalink.full_path}", "#{permalink.full_path}.png"
        if !success
          failures << permalink
        end
      end
      total_time_taken += time_taken
      puts "#{pages_tested}/#{links_to_test.count} - #{success ? 'SUCCESS' : 'FAILURE'} for #{permalink.full_path} in #{time_taken} seconds"
    end

    puts '-------'
    puts "RESULTS"
    puts '-------'
    puts "#{pages_tested} pages tested in #{total_time_taken}"
    puts "#{failures.count} failed pages:"
    failures.each do |permalink|
      puts permalink.full_path
    end
  end
end
