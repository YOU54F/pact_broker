# Application branch

Allowed methods: `GET`, `DELETE`

Path: `/applications/{application}/branches/{branch}`

Get or delete a application branch.

## Create

Branches cannot be created via the resource URL. They are created automatically when publishing contracts.

## Get

### Example

    curl http://broker/applications/Bar/branches/main -H "Accept: application/hal+json"

## Delete

Deletes a application branch. Does NOT delete the associated application versions.

Send a `DELETE` request to the branch resource.

    curl -XDELETE http://broker/applications/Bar/branches/main
