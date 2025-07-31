
# Application labels

Allowed methods: `GET`, `PUT`, `DELETE`

Path: `/applications/{application}/labels/{label}`

Get, create or delete application labels.

Applications can be queried by label with `/applications/label/{label}`.

Labels are also used to create generic webhooks that are triggered for subset of applications with label.
