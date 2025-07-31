# Application version

Allowed methods: `GET`, `PUT`, `DELETE`

Path: `/applications/{application}/versions/{version}`

## Example

    PUT http://broker/applications/Bar/versions/1e70030c6579915e5ff56b107a0fd25cf5df7464
    {
      "branch": "main",
      "buildUrl": "http://ci.mydomain/my-job/1"
    }
