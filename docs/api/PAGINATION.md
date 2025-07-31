# Pagination

Pagination of results is available for some endpoints used by the Pact Broker. These paginated responses can be used to programmatically load smaller subsections of the api results, in turn enabling improved performance and easier client side management of the data.

For endpoints that support pagination a paginated response can be retrieved using the following query parameters:

* `pageNumber=1`
* `pageSize=100`

eg.

```
https://pact-broker/applications?pageSize=100&pageNumber=1
```

Including one or both of these in the api call will result in a paginated response. Where only one parameter is included the other will use the default value specified above.

To retrieve the next or previous page of the paginated response use the URL provided in the response body under the `_links` section, labeled `next` or `previous`.
The first page will not have a previous link, while the last page will not have a next link.

The recommended approach to iterate the full list of resources is to fetch the first page, then call the `href` of the `next` relation until there is no `next` relation returned.

```
"_links": {
  "next": {
    "href": "http://pact-broker/applications?pageSize=100&pageNumber=2",
    "title": "Next page"
  }
}

```

## Paginated endpoints

The following endpoints in the Pact Broker support pagination via the above query parameters:

### [Applications](https://docs.pact.io/pact_broker/api/applications)

Ordered Alphabetically by the Application name.

### [Application Versions](https://docs.pact.io/pact_broker/overview#application-versions)

Ordered by date in reverse (most recent Application Version will be first).
