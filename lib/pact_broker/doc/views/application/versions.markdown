# Application versions

Allowed methods: `GET`

Path: `/applications/{application}/versions`

A list of application versions in order from newest to oldest.

To paginate, append `?pageNumber=x&pageSize=x` and follow the `next` relation until it is no longer present.
