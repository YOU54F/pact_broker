# Boots the broker from drift/config.ru and runs `drift verify` against it.
#
#   bundle exec ruby drift/run.rb          # or: bundle exec rake drift
#
# Exits with Drift's own exit code, so this is usable directly as a CI step.
#
# Requires the `drift` binary on PATH — see
# https://support.smartbear.com/swagger/contract-testing/docs/en/drift.html

require "fileutils"
require "net/http"
require "puma"
require "puma/configuration"
require "puma/launcher"
require "rack"

DRIFT_DIR = __dir__
PORT = ENV.fetch("DRIFT_SERVER_PORT", "9292").to_i
SERVER_URL = "http://localhost:#{PORT}"
OUTPUT_DIR = File.join(DRIFT_DIR, "output")

def wait_for_server
  100.times do
    begin
      response = Net::HTTP.get_response(URI("#{SERVER_URL}/diagnostic/status/heartbeat"))
      return true if response.is_a?(Net::HTTPSuccess)
    rescue StandardError # rubocop: disable Lint/SuppressedException
      # Not listening yet.
    end
    sleep 0.1
  end
  false
end

app = Rack::Builder.parse_file(File.join(DRIFT_DIR, "config.ru"))
# Rack 2 answered with [app, options]; Rack 3 answers with the app alone.
app = app.first if app.is_a?(Array)

# Puma, not WEBrick: WEBrick answers 411 to a request that carries a
# Content-Type but no body (Drift sends several), and hands Webmachine a
# request body that reads as empty the second time a resource asks for it,
# which breaks pact publication. Neither is a broker behaviour.
configuration = Puma::Configuration.new do | config |
  config.app(app)
  config.bind("tcp://127.0.0.1:#{PORT}")
  config.environment("production")
  # Puma's own logs would drown out Drift's; the app already logs through
  # config.log_stream.
  config.quiet(true)
end
launcher = Puma::Launcher.new(configuration, events: Puma::Events.new)
server_thread = Thread.new { launcher.run }
server_thread.abort_on_exception = true

abort("the broker did not start listening on #{SERVER_URL}") unless wait_for_server

FileUtils.rm_rf(OUTPUT_DIR)

# Read by drift/pact_broker.lua for its own /test/setup and /test/reset calls,
# so they hit the same port Drift itself is targeting.
ENV["DRIFT_PACT_BROKER_URL"] = SERVER_URL

success = system(
  "drift", "verify",
  "--test-files", File.join(DRIFT_DIR, "drift.yaml"),
  "--server-url", SERVER_URL,
  "--log-level", ENV.fetch("DRIFT_LOG_LEVEL", "error"),
  "--output-dir", OUTPUT_DIR,
  "--generate-result",
  chdir: DRIFT_DIR
)
exit_code = $?&.exitstatus || 1

launcher.stop

if success
  puts "\ndrift verify passed — see #{OUTPUT_DIR} for the reports."
else
  warn "\ndrift verify exited #{exit_code}; per-operation detail is in #{OUTPUT_DIR}."
end

exit(exit_code)
