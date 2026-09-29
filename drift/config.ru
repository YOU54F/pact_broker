# The app under test for the Drift suite: a real Pact Broker, against a
# throwaway SQLite database, with drift/test_state.rb's two seeding routes
# wrapped around it.
#
# Usable on its own — `bundle exec rackup drift/config.ru -p 9292` — if you
# want to poke at the broker by hand or run `drift verify` yourself; drift/run.rb
# boots exactly this and then shells out to the CLI for you.

require "fileutils"
require "pact_broker"

port = ENV.fetch("DRIFT_SERVER_PORT", "9292")
database_path = ENV.fetch("DRIFT_DATABASE_PATH", File.expand_path("../tmp/drift.sqlite3", __dir__))

# A clean database every boot: the suite asserts on response *shapes*, and a
# leftover row from a previous run is the kind of thing that makes an
# operation pass for the wrong reason.
FileUtils.mkdir_p(File.dirname(database_path))
FileUtils.rm_f(database_path)

app = PactBroker::App.new do | config |
  config.log_stream = :stdout
  config.log_level = ENV.fetch("DRIFT_APP_LOG_LEVEL", "warn").to_sym
  config.auto_migrate_db = true
  config.base_urls = ["http://localhost:#{port}"]
  config.database_url = "sqlite://#{database_path}"
end

# Required only now, not at the top: requiring TestDataBuilder pulls in the
# Sequel models, which resolve their database at class-definition time — so
# it has to come after PactBroker::App has connected.
require_relative "test_state"

run PactBroker::Drift::TestState.new(app)
