# Latest application version

Allowed methods: `GET`

Given a application name, this resource returns the latest application version according to the configured ordering scheme. Ordering will be by creation date of the version resource if `order_versions_by_date` is true, and will be by semantic order if `order_versions_by_date` is false.

Note that this resource represents a application (application) version, not a pact version.
