require "rspec/core"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new("spec:focus") do |task|
  task.rspec_opts = "--tag @focus"
end

RSpec::Core::RakeTask.new("spec:quick") do |task|
  task.rspec_opts = "--tag ~@no_db_clean --tag ~@migration --format progress"
end

RSpec::Core::RakeTask.new("regression") do |task|
  task.pattern = "regression/**{,/*/**}/*_spec.rb"
  task.rspec_opts = "--require ./regression/regression_helper.rb"
end

RSpec::Core::RakeTask.new("spec:slow") do |task|
  task.rspec_opts = "--tag @no_db_clean --tag @migration  --format progress"
end

task :set_simplecov_command_to_spec_quick do
  ENV["SIMPLECOV_COMMAND_NAME"] = "spec:quick"
end

task :set_simplecov_command_to_spec_slow do
  ENV["SIMPLECOV_COMMAND_NAME"] = "spec:slow"
end

task :enable_oas_coverage_check do
  ENV["OAS_COVERAGE_CHECK_ENABLED"] = "true"
end

task :disable_oas_coverage_check do
  ENV["OAS_COVERAGE_CHECK_ENABLED"] = nil
end


task "spec:quick" => ["set_simplecov_command_to_spec_quick", "enable_oas_coverage_check"]
task "spec:slow" => ["set_simplecov_command_to_spec_slow", "disable_oas_coverage_check"]
task :spec => ["spec:quick", "spec:slow"]

desc "Lint OpenAPI spec with Spectral"
task :lint_openapi do
  oas_file = ENV["OAS_FILE"] || "specs/pact_broker_openapi.yaml"
  sh "npx @stoplight/spectral-cli lint \"#{oas_file}\""
end

desc "Lint Arazzo spec with Spectral"
task :lint_arazzo do
  arazzo_file = ENV["ARAZZO_FILE"] || "specs/pact_broker_arazzo.yaml"
  sh "npx @stoplight/spectral-cli lint \"#{arazzo_file}\""
end

desc "Run Arazzo workflow tests"
task :test_arazzo => [:start_pact_server] do
  arazzo_file = ENV["ARAZZO_FILE"] || "specs/pact_broker_arazzo.yaml"
  input_file = ENV["INPUT_FILE"] || "specs/inputs-publish-contracts.json"
  hostname = ENV["HOSTNAME"] || "localhost:9292"
  workflow_id = ENV["WORKFLOW_ID"] || "publish-consumer-contract"
  inputs = File.read(input_file)
  sh "uvx arazzo-runner execute-workflow " \
     "#{arazzo_file} " \
     "--workflow-id #{workflow_id} " \
     "--server-variables '{\"PACTBROKER_RUNNER_SERVER_HOSTNAME\": \"#{hostname}\"}' " \
     "--inputs '#{inputs}'"
ensure
  Rake::Task[:stop_pact_server].invoke
end

desc "Start the Pact server"
task :start_pact_server do
  FileUtils.mkdir_p("log")
  @pact_server_pid = spawn("bundle exec rackup -p 9292 -P broker.pid", out: "log/pact_server.log", err: "log/pact_server.log")
  sleep 2 # Give the server time to start
  at_exit { Rake::Task[:stop_pact_server].invoke }
end

desc "Stop the Pact server"
task :stop_pact_server do
  pid_file = "broker.pid"
  if File.exist?(pid_file)
    pid = File.read(pid_file).strip.to_i
    if Gem.win_platform?
      system("taskkill /PID #{pid} /F > NUL 2>&1")
    else
      Process.kill("TERM", pid)
    end
    File.delete(pid_file) rescue nil
  elsif defined?(@pact_server_pid) && @pact_server_pid
    if Gem.win_platform?
      system("taskkill /PID #{@pact_server_pid} /F > NUL 2>&1")
    else
      Process.kill("TERM", @pact_server_pid)
      Process.wait(@pact_server_pid)
    end
    @pact_server_pid = nil
  else
    # Try to kill any rackup running on 9292
    pid = `lsof -i :9292 -t`.strip
    unless pid.empty?
      if Gem.win_platform?
        system("taskkill /PID #{pid} /F > NUL 2>&1")
      else
        Process.kill("TERM", pid.to_i)
      end
    end
  end
end
