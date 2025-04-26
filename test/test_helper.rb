# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require "rails/test_help"
require 'database_cleaner/active_record'
require 'awesome_print'
# require 'minitest/reporters'
require 'minitest/mock'

# MiniTest::Reporters.use!

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
ActiveSupport::TestCase.use_instantiated_fixtures = false

DatabaseCleaner::ActiveRecord.config_file_location = File.expand_path("../dummy/config/database.yml", __FILE__)

DatabaseCleaner[:active_record].strategy = :truncation
DatabaseCleaner[:active_record, db: :test]
DatabaseCleaner[:active_record, db: :remote]

Rails.application.eager_load!

class ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:active_record].start
  end

  teardown do
    DatabaseCleaner[:active_record].clean
  end
end
