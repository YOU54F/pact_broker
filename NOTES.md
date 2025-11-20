# arazzo


1. allow option to override url
2. allow option to print out verbose request / response
3. better failure errors when items not defined (success criterea)
4. inputs are mandatory otherwise error from itarazzo
5. inputs from ref
   1. array are supported, but not with objects
   2. objects for simple types not supported
6. read hal+json content types

```
Caused by: de.leidenheit.core.exception.ItarazzoUnsupportedException: Reading nested properties of response body requires a content type of JSON|XML
```


this doesnt work

    inputs:
      $ref: "#/components/inputs/apply_coupon_input"

```
components:
  inputs:
    apply_coupon_input:
      type: object
      properties:
        my_pet_tags:
          type: array
          items:
            type: string
          description: Desired tags to use when searching for a pet, in CSV format (e.g. "puppy, dalmatian")
        store_id:
          $ref: "#/components/inputs/store_id"
    store_id:
      type: string
      description: Indicates the domain name of the store where the customer is browsing or buying pets, e.g. "pets.example.com" or "pets.example.co.uk".
```

this does work

    inputs:
      $ref: "#/components/inputs/apply_coupon_input"

```
components:
  inputs:
    apply_coupon_input:
      type: object
      properties:
        my_pet_tags:
          type: array
          items:
            type: string
          description: Desired tags to use when searching for a pet, in CSV format (e.g. "puppy, dalmatian")
        store_id:
          $ref: "#/components/inputs/store_id"
```


This doesnt work

    inputs:
      $ref: "#/components/inputs/store_id"

```
components:
  inputs:
    store_id:
      type: string
      description: Indicates the domain name of the store where the customer is browsing or buying pets, e.g. "pets.example.com" or "pets.example.co.uk".
   