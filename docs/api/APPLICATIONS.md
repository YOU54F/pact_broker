
# Applications


## Application

Path: `/applications/:application_name`<br/>
Allowed methods: `GET`, `PUT`, `PATCH`, `DELETE`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "name": "foo",
  "displayName": "Foo",
  "repositoryUrl": "https://github.com/example-organization/foo",
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_embedded": {
    "latestVersion": {
      "number": "3e1f00a04",
      "_links": {
        "self": {
          "title": "Version",
          "name": "3e1f00a04",
          "href": "https://pact-broker/applications/foo/versions/3e1f00a04"
        }
      }
    },
    "labels": [

    ]
  },
  "_links": {
    "self": {
      "href": "https://pact-broker/applications/foo"
    },
    "pb:versions": {
      "href": "https://pact-broker/applications/foo/versions"
    },
    "pb:version": {
      "title": "Get, create or delete a application version",
      "href": "https://pact-broker/applications/foo/versions/{version}",
      "templated": true
    },
    "pb:version-tag": {
      "title": "Get, create or delete a tag for a version of foo",
      "href": "https://pact-broker/applications/foo/versions/{version}/tags/{tag}",
      "templated": true
    },
    "pb:branch-version": {
      "title": "Get or add/create a version for a branch of foo",
      "href": "https://pact-broker/applications/foo/branches/{branch}/versions/{version}",
      "templated": true
    },
    "pb:label": {
      "title": "Get, create or delete a label for foo",
      "href": "https://pact-broker/applications/foo/labels/{label}",
      "templated": true
    },
    "pb:can-i-deploy-badge": {
      "title": "Can I Deploy foo badge",
      "href": "https://pact-broker/applications/foo/latest-version/{tag}/can-i-deploy/to/{environmentTag}/badge",
      "templated": true
    },
    "pb:can-i-deploy-branch-to-environment-badge": {
      "title": "Can I Deploy foo from branch to environment badge",
      "href": "https://pact-broker/applications/foo/branches/{branch}/latest-version/can-i-deploy/to-environment/{environment}/badge",
      "templated": true
    },
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/{rel}?context=application",
        "templated": true
      }
    ]
  }
}
```


### PUT

PUT replaces the entire resource with the specified body, so missing properties will effectively be nulled. Embedded properties (eg. versions) will not be affected.

#### Request

Headers: `{"Content-Type":"application/json","Accept":"application/hal+json"}`<br/>
Body:

```
{
  "displayName": "Foo",
  "repositoryUrl": "https://github.com/example/foo",
  "repositoryName": "foo",
  "repositoryNamespace": "example",
  "mainBranch": "main"
}
```


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "name": "foo",
  "displayName": "Foo",
  "repositoryUrl": "https://github.com/example/foo",
  "repositoryName": "foo",
  "repositoryNamespace": "example",
  "mainBranch": "main",
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_embedded": {
    "latestVersion": {
      "number": "3e1f00a04",
      "_links": {
        "self": {
          "title": "Version",
          "name": "3e1f00a04",
          "href": "https://pact-broker/applications/foo/versions/3e1f00a04"
        }
      }
    },
    "labels": [

    ]
  },
  "_links": {
    "self": {
      "href": "https://pact-broker/applications/foo"
    },
    "pb:versions": {
      "href": "https://pact-broker/applications/foo/versions"
    },
    "pb:version": {
      "title": "Get, create or delete a application version",
      "href": "https://pact-broker/applications/foo/versions/{version}",
      "templated": true
    },
    "pb:version-tag": {
      "title": "Get, create or delete a tag for a version of foo",
      "href": "https://pact-broker/applications/foo/versions/{version}/tags/{tag}",
      "templated": true
    },
    "pb:branch-version": {
      "title": "Get or add/create a version for a branch of foo",
      "href": "https://pact-broker/applications/foo/branches/{branch}/versions/{version}",
      "templated": true
    },
    "pb:label": {
      "title": "Get, create or delete a label for foo",
      "href": "https://pact-broker/applications/foo/labels/{label}",
      "templated": true
    },
    "pb:can-i-deploy-badge": {
      "title": "Can I Deploy foo badge",
      "href": "https://pact-broker/applications/foo/latest-version/{tag}/can-i-deploy/to/{environmentTag}/badge",
      "templated": true
    },
    "pb:can-i-deploy-branch-to-environment-badge": {
      "title": "Can I Deploy foo from branch to environment badge",
      "href": "https://pact-broker/applications/foo/branches/{branch}/latest-version/can-i-deploy/to-environment/{environment}/badge",
      "templated": true
    },
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/{rel}?context=application",
        "templated": true
      }
    ]
  }
}
```


### PATCH

PATCH with the Content-Type application/merge-patch+json merges the application's existing properties with those from the request body. Embedded properties (eg. versions) will not be affected.

#### Request

Headers: `{"Content-Type":"application/merge-patch+json","Accept":"application/hal+json"}`<br/>
Body:

```
{
  "displayName": "Foo",
  "repositoryUrl": "https://github.com/example/foo",
  "repositoryName": "foo",
  "repositoryNamespace": "example",
  "mainBranch": "main"
}
```


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "name": "foo",
  "displayName": "Foo",
  "repositoryUrl": "https://github.com/example/foo",
  "repositoryName": "foo",
  "repositoryNamespace": "example",
  "mainBranch": "main",
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_embedded": {
    "latestVersion": {
      "number": "3e1f00a04",
      "_links": {
        "self": {
          "title": "Version",
          "name": "3e1f00a04",
          "href": "https://pact-broker/applications/foo/versions/3e1f00a04"
        }
      }
    },
    "labels": [

    ]
  },
  "_links": {
    "self": {
      "href": "https://pact-broker/applications/foo"
    },
    "pb:versions": {
      "href": "https://pact-broker/applications/foo/versions"
    },
    "pb:version": {
      "title": "Get, create or delete a application version",
      "href": "https://pact-broker/applications/foo/versions/{version}",
      "templated": true
    },
    "pb:version-tag": {
      "title": "Get, create or delete a tag for a version of foo",
      "href": "https://pact-broker/applications/foo/versions/{version}/tags/{tag}",
      "templated": true
    },
    "pb:branch-version": {
      "title": "Get or add/create a version for a branch of foo",
      "href": "https://pact-broker/applications/foo/branches/{branch}/versions/{version}",
      "templated": true
    },
    "pb:label": {
      "title": "Get, create or delete a label for foo",
      "href": "https://pact-broker/applications/foo/labels/{label}",
      "templated": true
    },
    "pb:can-i-deploy-badge": {
      "title": "Can I Deploy foo badge",
      "href": "https://pact-broker/applications/foo/latest-version/{tag}/can-i-deploy/to/{environmentTag}/badge",
      "templated": true
    },
    "pb:can-i-deploy-branch-to-environment-badge": {
      "title": "Can I Deploy foo from branch to environment badge",
      "href": "https://pact-broker/applications/foo/branches/{branch}/latest-version/can-i-deploy/to-environment/{environment}/badge",
      "templated": true
    },
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/{rel}?context=application",
        "templated": true
      }
    ]
  }
}
```


