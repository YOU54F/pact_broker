# Application branch version

Allowed methods: `GET`, `PUT`, `DELETE`

Path: `/applications/{application}/branches/{branch}/versions/{version}`

Get or add/create a application version for a branch.

## Create

### Example

Add a version to a branch. The application and branch are automatically created if they do not exist.

    curl -XPUT http://broker/applications/Bar/branches/main/versions/1e70030c6579915e5ff56b107a0fd25cf5df7464 \
          -H "Content-Type: application/json" -d "{}"


## Delete

Removes a application version from a branch. Does not delete the actual application version.

Send a `DELETE` request to the branch version resource.

    curl -XDELETE http://broker/applications/Bar/branches/main/versions/1e70030c6579915e5ff56b107a0fd25cf5df7464
