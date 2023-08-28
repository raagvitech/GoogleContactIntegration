/* class Name		: GContactBatch
* Description		: To update bulk contact records from SF to G-contacts. It is call from trigger
*/
public class GContactBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private Set<Id> idsets;
    public GContactBatch(Set<Id> idsets){
        this.idsets = idsets;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, FirstName, LastName, ExternalSourceId__c, etag__c FROM Contact WHERE Id IN: idsets]);
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> conList) {
        // make callout
        updateBulkGcontacts.createContact(conList);
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}