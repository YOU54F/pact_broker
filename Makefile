PACTICIPANT := 'Pact Broker'
GITHUB_REPO := you54f/pact_broker
CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID := "7feab4e2-cad2-4ef2-b5d2-0fd5676e3d45"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli"


## =====================
## Arazzo
## =====================

OAS_FILE?=specs/pact_broker_openapi.yaml
ARAZZO_FILE?=specs/pact_broker_arazzo.yaml
INPUT_FILE=specs/inputs-publish-contracts.json
HOSTNAME?=localhost:9292
WORKFLOW_ID?=publish-consumer-contract

lint_openapi:
	npx @stoplight/spectral-cli lint "${OAS_FILE}"

lint_arazzo:
	npx @stoplight/spectral-cli lint "${ARAZZO_FILE}"

test_arazzo:
	uvx arazzo-runner execute-workflow \
		specs/pact_broker_arazzo.yaml \
		--workflow-id ${WORKFLOW_ID} \
		--server-variables '{"PACTBROKER_RUNNER_SERVER_HOSTNAME": "${HOSTNAME}"}' \
		--inputs '$(shell cat ${INPUT_FILE})'


## =====================
## Pactflow set up tasks
## =====================

# export the GITHUB_TOKEN environment variable before running this
create_github_token_secret:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"githubToken\",\"description\":\"Github token\",\"value\":\"${GITHUB_TOKEN}\"}"

# In order to setup the webhook, the pacticipant needs to be created. It is auto-created on publish
# but this is useful for setting up the webhook before publishing any pacts.
create_pacticipant:
	@"${PACT_CLI}" \
	  broker create-or-update-pacticipant \
	  --name ${PACTICIPANT}

create_or_update_contract_requiring_verification_published_webhook:
	"${PACT_CLI}" \
	  broker create-or-update-webhook \
	  "https://api.github.com/repos/${GITHUB_REPO}/dispatches" \
	  --header 'Content-Type: application/json' 'Accept: application/vnd.github.everest-preview+json' 'Authorization: Bearer $${user.githubToken}' \
	  --request POST \
	  --data '{ "event_type": "contract_requiring_verification_published","client_payload": { "pact_url": "$${pactbroker.pactUrl}", "sha": "$${pactbroker.providerVersionNumber}", "branch":"$${pactbroker.providerVersionBranch}" , "message": "Verify changed pact for $${pactbroker.consumerName} version $${pactbroker.consumerVersionNumber} branch $${pactbroker.consumerVersionBranch} by $${pactbroker.providerVersionNumber} ($${pactbroker.providerVersionDescriptions})" } }' \
	  --uuid ${CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID} \
	  --provider ${PACTICIPANT} \
	  --contract-requiring-verification-published \
	  --description "contract_requiring_verification_published for ${PACTICIPANT}"

test_contract_requiring_verification_published_webhook:
	@curl -v -X POST ${PACT_BROKER_BASE_URL}/webhooks/${CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID}/execute -H "Authorization: Bearer ${PACT_BROKER_TOKEN}"

