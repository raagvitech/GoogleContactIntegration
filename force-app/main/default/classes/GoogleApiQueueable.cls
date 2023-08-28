/* class Name		: GoogleApiQueueable
* Description		: GoogleContactTrigger handler class. executing batch or normal function based on number of records.
* Custom metadata	: GContactBatchLimit with field batchLimit = 10
*/
public class GoogleApiQueueable implements Queueable,Database.AllowsCallouts {
    public static Boolean isDisableTrigger = false;
    private List<Contact> newContact;
    private Boolean isUpdate;
    public GoogleApiQueueable(List<Contact> newContact ,Boolean isUpdate) {
        this.newContact = newContact;
        this.isUpdate = isUpdate;
    }
    
    
    public void execute(QueueableContext context) {
        List<GContactBatchLimit__mdt> mcs = GContactBatchLimit__mdt.getAll().values();
        Integer batchLimit = Integer.valueOf(mcs[0].batchLimit__c);
        Set<Id> idsets = new Set<Id>();
        for(Contact con : newContact){
            idsets.add(con.Id);
        }
        if(isUpdate){
            updateBulkGcontacts.updateContact(idsets); 
        } else { 
            if(newContact.size() > batchLimit){
                GContactBatch batch = new GContactBatch(idsets);
                Database.executeBatch(batch, 15);  
            } else {
                updateBulkGcontacts.createContact(idsets);
            }
            
        }
        
    }
}