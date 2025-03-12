# Secrets

*Collection resource*

Path: `/secrets`

Allowed methods: `GET`, `POST`

*Individual resource*

Path: `/secrets/{uuid}`

Allowed methods: `GET`, `PUT`, `DELETE`

Webhooks are HTTP requests that are executed asynchronously after certain events occur in the Pact Broker, that can be used to create a workflow or notify people of changes to the data contained in the Pact Broker. The most common use for webhooks is to trigger builds when a pact has changed or a verification result has been published, but they can also be used for conveying information like posting notifications to Slack, or commit statuses to Github.

### Setup

Create a broker encryption key

`PACT_BROKER_SECRETS_ENCRYPTION_KEY=ttDJ1PnVbxGWhIe3T12UHoEfHKB4AvoxdW0JWOg98gE=`

### Creation

1. Create a secret

```sh
curl http://localhost:9292/secrets \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"name":"somesecret", "value":"supersecretsquirrel"}'
```

2. Update a secret

```sh
curl http://localhost:9292/secrets/{uuid} \
      -X PUT \
      -H "Content-Type: application/json" \
      -d '{"name":"somesecret", "value":"supersecretsquirrel"}'
```
### Usage

Reference your secret, in a webhook template.

The following variables may be used in the request path, parameters or body, and will be replaced with their appropriate values at runtime.

* `${secret.<secretName>}` - Dynamically substitute a stored secret. Replace `<secretName>` with the name of the secret.

Example usage:

    {
      "events": [{
        "name": "contract_content_changed"
      }],
      "request": {
        "method": "POST",
        "url": "http://example.org/something",
        "body": {
          "thisPactWasPublished" : "${pactbroker.pactUrl}",
          "some_secret": "${secret.myStoredSecret}"
        }
      }
    }

### Deletion

Delete a secret

```sh
curl http://localhost:9292/secrets/{uuid} -X DELETE
```