# Nexus

An integration pattern.

A limitation is scale. This integration is over https, and so will work if you have low throughput velocity (1 m/s maybe) but wont work very well if you have high throughput velocity (lots-o-m/s). It does however add value over the top of Event Hub. For example, the ability to perform schema validation over the the payload before it is submitted to Event Hub. And all the other nice things you can do with an API Management policy like OAuth2/OpenId Connect. And is a very low barrier to entry as an integration solution.

## Deployment

To deploy run the following (works for API Management or the API):

`az deployment sub create --name $(New-Guid) --location 'westeurope' --template-file ./main.bicep --parameters ./env/dev.bicepparam`

`az deployment group create -g rg-nexus-westeu-dev-01 --name $(New-Guid) --template-file ./main.bicep --parameters ./env/dev.bicepparam`

## REST Client

There are some samples in `./test/dev.http` that take a bearer token in order to send a event to event hub directly using a rest client. To get the `bearer` token, you can run this command from the command line:

`az account get-access-token --resource=https://servicebus.azure.net/ --query accessToken -o tsv`

## Managed Identity

API Management talks to Event Hub using managed identity (see the policy `./policies/*`). So give API Management `Event Hub Data Sender` permissions on the namespace or the event hub.

## Update

In `./api/` there is an example of a deployment that does a lot of the above through automation.

## Storage

To get the token using the Azure CLI:

`az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv`

And set the `Storage Blob Data Owner` permissions on the storage account for the client identity.
