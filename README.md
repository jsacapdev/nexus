# Nexus

An integration pattern with a very low barrier to entry as an integration solution.

## Deployment

To deploy run the following (works for API Management):

`az deployment sub create --name $(New-Guid) --location 'westeurope' --template-file ./main.bicep --parameters ./env/dev.bicepparam`

To deploy run the following (works for the API):

`az deployment group create -g rg-nexus-westeu-dev-01 --name $(New-Guid) --template-file ./main.bicep --parameters ./env/dev.bicepparam`

## API

In `./api/` there is an example of a deployment that does a lot of the above through automation.

## REST Client

There are some samples in `./test/dev.http` that take a bearer token in order to send a event to event hub directly using a rest client. To get the `bearer` token, you can run this command from the command line:

`az account get-access-token --resource=https://servicebus.azure.net/ --query accessToken -o tsv`

### Storage

To get the token using the Azure CLI:

`az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv`

And set the `Storage Blob Data Owner` permissions on the storage account for the client identity.

##

``` pwsh
Connect-AzAccount -DeviceCode
```
