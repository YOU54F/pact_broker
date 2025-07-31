# Applications

Allowed methods: `GET`, `PATCH`, `DELETE`

Path: `/applications`

"Application" - a party that participates in a pact (ie. a Consumer or a Provider).

## Creating applications

### When publishing pacts

Participants are created automatically when a pact is published to the pact broker. The name is based on the URL compontents used to publish the pact (ie. /pacts/provider/$PROVIDER\_NAME/consumer/$CONSUMER\_NAME/version/$CONSUMER\_VERSION), not on the contents of the pact, as the Pact Broker is designed to be agnostic of the actual pact format as much as possible.

### Explicitly

```
$ curl -X POST http://pact-broker/applications \
  -H "Content-Type: application/json" \
  -H "Accept: application/hal+json" \
  -d '{ "name": "my-consumer", "displayName": "My Consumer" }'
```

Properties:

`name`: The name that will be used to identify the application in URLs.
`displayName`: The name to display in the UI
`repositoryUrl`: The URL at which to view the repository in a browser.
`repositoryName`: The name of the repository, without any namespace.
`repositoryNamespace`: The namespace of the repository (called "organization" in Github).

## Deleting applications

Deleting a application will delete all associated pacts, versions, tags and webhooks. To delete a application, send a DELETE request to the relevant application URL via the HAL browser or any other HTTP client.

    $ curl -X DELETE http://pact-broker/applications/My%20Consumer
