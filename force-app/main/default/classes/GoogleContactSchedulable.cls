/* class Name		: GoogleContactBatch
* Description		: Schedulable class to sync g-contacts with SF contact that runs once in every day.
*/
public class GoogleContactSchedulable implements Schedulable, Database.AllowsCallouts {
    static List<sObject> gcontactList = new List<sObject>();
    
    public void execute(SchedulableContext sc) {
        GoogleContactsHelper.makeGoogleContactsCallout();
        
    }
}