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