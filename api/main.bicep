param apiManagementName string

var apiName = 'schema-validation-sample'
var apiSchemaGuid = guid('${resourceGroup().id}-${apiName}-schema')
var schemaExampleUser1 = 'some.jo@mail.com'
var operation_addPerson = 'addperson'
var serviceBusEndpoint = 'https://sb-nexus-westeu-dev-01.servicebus.windows.net'

var personSchema = {
  firstName: {
    type: 'string'
  }
  lastName: {
    type: 'string'
  }
  age: {
    type: 'integer'
    minimum: 0
  }
  email: {
    type: 'string'
    format: 'email'
    pattern: '^\\S+@\\S+\\.\\S+$'
  }
}

var requiredPersonSchema = [
  'firstName'
  'lastName'
]

var personExample = {
  firstName: 'Some'
  lastName: 'Jo'
  age: 25
  email: schemaExampleUser1
}

var policySchema = '''
<!--
    - Policies are applied in the order they appear.
    - Position <base/> inside a section to inherit policies from the outer scope.
    - Comments within policies are not preserved.
    - Add policies as children to the <inbound>, <outbound>, <backend>, and <on-error> elements.
-->
<policies>
    <!-- Throttle, authorize, validate, cache, or transform the requests -->
    <inbound>

        <!-- Validation -->
        {0}
        <!-- Authorization -->
        {1}
        <base />
    </inbound>
    <!-- Control if and how the requests are forwarded to services  -->
    <backend>
        <base />
    </backend>
    <!-- Customize the responses -->
    <outbound>
        <base />
    </outbound>
    <!-- Handle exceptions and customize error responses  -->
    <on-error>
        <base />
    </on-error>
</policies>
'''

var validatePersonPolicy = '''
        <validate-content unspecified-content-type-action="prevent" max-size="1024" size-exceeded-action="prevent" errors-variable-name="validationerrors">
            <content type="application/json" validate-as="json" action="prevent" schema-id="personSchema" />
        </validate-content>
'''

var authorizationPolicy = '''
        <set-header name="Content-Type" exists-action="override">
            <value>application/atom+xml;type=entry;charset=utf-8</value>
        </set-header>
        <set-header name="Host" exists-action="override">
            <value>sb-nexus-westeu-dev-01.servicebus.windows.net</value>
        </set-header>
        <authentication-managed-identity resource="https://servicebus.azure.net" output-token-variable-name="msi-access-token" ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@(String.Concat("Bearer ",(string)context.Variables["msi-access-token"]))</value>
        </set-header>
'''

var personPolicy = format(policySchema, validatePersonPolicy, authorizationPolicy)

resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementName
}

resource apimPersonSchema 'Microsoft.ApiManagement/service/schemas@2021-08-01' = {
  name: 'personSchema'
  parent: apim
  properties: {
    schemaType: 'json'
    description: 'Schema for a Person Object'
    document: any({
      type: 'array'
      items: {
        type: 'object'
        properties: personSchema
        required: requiredPersonSchema
      }
    })
  }
}

resource apiManagement_apiName 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiName
  parent: apim
  properties: {
    displayName: 'Person Schema Validation Example'
    subscriptionRequired: true
    path: 'person-schema-validation'
    protocols: [
      'https'
    ]
    isCurrent: true
    description: 'Personal data ingestion'
    subscriptionKeyParameterNames: {
      header: 'Subscription-Key-Header-Name'
      query: 'subscription-key-query-param-name'
    }
  }
}

resource apiManagement_apiName_apiSchemaGuid 'Microsoft.ApiManagement/service/apis/schemas@2021-08-01' = {
  parent: apiManagement_apiName
  name: apiSchemaGuid
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: any({
      components: {
        schemas: {
          Definition_Person: {
            type: 'object'
            properties: personSchema
            required: requiredPersonSchema
            example: personExample
          }
        }
      }
    })
  }
}

resource apiManagement_apiName_operation_addPerson 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: apiManagement_apiName
  name: operation_addPerson

  dependsOn: [
    apiManagement_apiName_apiSchemaGuid
  ]
  properties: {
    request: {
      headers: [
        {
          name: 'Content-Type'
          type: 'string'
          required: true
          values: [
            'application/json'
          ]
        }
      ]
      representations: [
        {
          contentType: 'application/json'
          schemaId: apiSchemaGuid
          typeName: 'Definition_Person'
        }
      ]
    }
    displayName: 'Add Person'
    description: 'Add Person Information to Event Hub. \nThe Request Body is parsed to ensure correct schema.'
    method: 'POST'
    urlTemplate: '/nexus001/messages'
  }
}

resource serviceName_apiName_policy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: apiManagement_apiName
  name: 'policy'
  properties: {
    value: '<!-- All operations-->\r\n<policies>\r\n  <inbound>\r\n    <base/>\r\n    <set-backend-service base-url="${serviceBusEndpoint}" />\r\n  <set-header name="Content-Type" exists-action="override">\r\n  <value>application/json</value>\r\n  </set-header>\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'rawxml'
  }
}

resource apiManagement_apiName_operation_addPerson_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  parent: apiManagement_apiName_operation_addPerson
  name: 'policy'
  properties: {
    value: personPolicy
    format: 'rawxml'
  }
}
