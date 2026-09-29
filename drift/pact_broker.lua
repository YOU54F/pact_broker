-- Drift lifecycle hooks for the Pact Broker API test suite.
--
-- `drift/run.rb` boots the app with two test-only routes mounted:
--   POST /test/setup/{operationId} — seeds the DB for one operation, and
--     returns whatever it generated (UUIDs, pact-version SHAs) as JSON,
--     since those can't be hardcoded in drift.yaml.
--   POST /test/reset — truncates the DB.
--
-- This script calls the former on "operation:started" (before Drift builds
-- the request, so ${functions:...} values below are ready in time) and the
-- latter on "operation:finished", storing the setup response in between so
-- drift.yaml's parameters can read out of it by field name.

local server_url = os.getenv("DRIFT_PACT_BROKER_URL") or "http://localhost:9292"

local current_context = {}

local function get(field)
  return function()
    return current_context[field]
  end
end

local exports = {
  event_handlers = {
    ["operation:started"] = function(event, data)
      local operation_id = data[2]
      local response = http({
        url = server_url .. "/test/setup/" .. operation_id,
        method = "POST",
      })
      if response.status ~= 200 then
        print("test state setup failed for " .. operation_id .. ": " .. tostring(response.body))
        current_context = {}
        return
      end
      -- drift's `http` decodes a JSON response body for us, so this is
      -- already the table of seeded values, not a string to parse.
      current_context = response.body or {}
    end,

    ["operation:finished"] = function(event, data)
      http({
        url = server_url .. "/test/reset",
        method = "POST",
      })
      current_context = {}
    end,
  },

  exported_functions = {
    consumer_name = get("consumerName"),
    provider_name = get("providerName"),
    consumer_version_number = get("consumerVersionNumber"),
    provider_version_number = get("providerVersionNumber"),
    pact_version_sha = get("pactVersionSha"),
    environment_name = get("environmentName"),
    environment_uuid = get("environmentUuid"),
    deployed_version_uuid = get("deployedVersionUuid"),
    released_version_uuid = get("releasedVersionUuid"),
    webhook_uuid = get("webhookUuid"),
  },
}

return exports
