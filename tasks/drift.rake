desc "Verify the API against the OpenAPI spec in drift/openapi.json using Drift"
task :drift do
  ruby "drift/run.rb"
end
