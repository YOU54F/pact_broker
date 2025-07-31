# Latest application version with the specified tag

Allowed methods: `GET`

Given a application name and a application version tag name, this resource returns the latest application version with the specified tag. Note that the "latest" is determined by the creation date of the application version resource (or the semantic order if `order_versions_by_date` is false), not by the creation date of the tag.
