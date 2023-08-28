# GoogleContactIntegration
Integrating contacts between salesforce and google

1. Prerequisite for Contact Object. 
    1.1 Created the field ExternalSourceId to store the external ID (resourceName) in Salesforce.
    1.2 Created the field etag to store the unique Id (etag) in Salesforce.

2. From Google contacts to Salesforce
    2.1 Created the GoogleContactSchedulable class to sync Google contacts with Salesforce.
    2.2 This class creates or updates contacts in Salesforce based on Google contacts and can be scheduled to run once a day.

3. From Salesforce to Google contacts.
    3.1 Develop a GoogleContactTrigger that invokes the GoogleApiQueueable class on insert and update operations.
    3.2 Created the GContactBatchLimit custom metadata field to determine the batch limit value. If the number of contacts is below this limit, invoke the updateBulkGcontacts method for making callouts.
    3.3 If the number of contacts exceeds the defined limit, implement the GContactBatch batch class to make callouts with a batch limit of 15.

2. Reference 
    https://developers.google.com/people/api/rest