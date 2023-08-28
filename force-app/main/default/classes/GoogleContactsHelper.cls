/* class Name		: GoogleContactsHelper
* Description		: class to sync g-contacts with SF contact.
*/
public class GoogleContactsHelper {
    // Method to make callout to Google Contacts API using Named Credential
    @future(callout=true)
    public static void makeGoogleContactsCallout() {
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Connectsalesforces' + '/v1/people/me/connections?personFields=names,emailAddresses,phoneNumbers');
        request.setMethod('GET');
        // Send the HTTP request
        Http http = new Http();
        HttpResponse response = http.send(request);
        // Handle the API response
        if (response.getStatusCode() == 200) {
            // Successful API call
            String responseBody = response.getBody();
            System.debug('API Response: ' + responseBody);
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> namesList = new List<Object>();
            if (params.containsKey('connections')) {
                namesList = (List<Object>) params.get('connections');
            }
            
            Map<String, Object> resourceToContact = new  Map<String, Object>();
            for(Object obj : namesList){
                Map<String, Object> obj2 = (Map<String, Object>) obj;
                resourceToContact.put((String)obj2.get('resourceName'),obj);
            }
            
            List<Contact> existingConList = [SELECT Id, FirstName, LastName, ExternalSourceId__c, etag__c FROM Contact WHERE ExternalSourceId__c = : resourceToContact.keySet()];
            Map<String, Contact> existingConMap = new  Map<String, Contact>();
            for(Contact con : existingConList){
                existingConMap.put(con.ExternalSourceId__c, con);
            }
            
            List<Contact> updateContact = new List<Contact>();
            List<Contact> newContact = new List<Contact>();
            
            for(Object obj : namesList){
                Map<String, Object> gCon = (Map<String, Object>) obj;
                String emailId = '';
                String phoneNumber = '';
                if(gCon.keySet().contains('emailAddresses')){
                    List<Object> emailList = (List<Object>) gCon.get('emailAddresses');
                    Map<String, Object> emailMap = (Map<String, Object>) emailList[0];
                    emailId =(String) emailMap.get('value');
                }
                if(gCon.keySet().contains('phoneNumbers')){
                    
                    List<Object> phoneList = (List<Object>) gCon.get('phoneNumbers');
                    Map<String, Object> phoneMap = (Map<String, Object>) phoneList[0];
                    phoneNumber =(String) phoneMap.get('value');
                }
                String resName= (String)gCon.get('resourceName');
                List<Object> namesList1 = (List<Object>) gCon.get('names');
                Map<String, Object> nameMap = (Map<String, Object>) namesList1[0];
                if(existingConMap.keySet().contains(resName)){
                    
                    Contact con = existingConMap.get(resName);
                    con.Id = existingConMap.get(resName).Id;
                    con.LastName = (String) nameMap.get('givenName');
                    con.FirstName = (String) nameMap.get('familyName');
                    con.etag__c = (String) gCon.get('etag');
                    con.ExternalSourceId__c = resName;
                    if(emailId != '')
                        con.Email = emailId;
                    if(phoneNumber != '')
                        con.Phone = phoneNumber;
                    System.debug('existing records == '+ con);
                    updateContact.add(con);    
                } else {
                    Contact newCon = new Contact();
                    newCon.LastName = (String) nameMap.get('givenName');
                    newCon.FirstName = (String) nameMap.get('familyName');
                    newCon.etag__c = (String) gCon.get('etag');
                    newCon.ExternalSourceId__c = resName;
                    if(emailId != '')
                        newCon.Email = emailId;
                    if(phoneNumber != '')
                        newCon.Phone = phoneNumber;
                    newContact.add(newCon);
                }
            }
            
            if(!updateContact.isEmpty()){
                GoogleApiQueueable.isDisableTrigger = true;
                update updateContact;
                GoogleApiQueueable.isDisableTrigger = false;
            }
            
            if(!newContact.isEmpty()){
                GoogleApiQueueable.isDisableTrigger = true;
                insert newContact;
                GoogleApiQueueable.isDisableTrigger = false;
            }    
        } 
    }
}