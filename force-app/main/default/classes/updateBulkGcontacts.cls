/* class Name		: updateBulkGcontacts
* Description		: class to sync SF with g-contacts for bulk updates.
*/
public class updateBulkGcontacts {
    
    public static void createContact(Set<Id> conIdsets){
        List<Contact> conList = [SELECT Id, FirstName, LastName, Email, Phone, ExternalSourceId__c, etag__c FROM contact WHERE Id IN :conIdsets];
        createContact(conList);
    }
    
    public static void createContact(List<Contact> conList){	
        Map<String, Contact> sfConactMap = new Map<String, Contact>();
        List<Contact> updateGConacts = new List<Contact>();
        Set<Id> conIds = new Set<Id>();
        Http http=new Http();
        HttpRequest req = new HttpRequest();      
        req.setEndpoint('callout:Connectsalesforces' +'/v1/people:batchCreateContacts?sources=READ_SOURCE_TYPE_CONTACT');
        List<Map<String, Map<String, Object>>> conactList = new List<Map<String, Map<String, Object>>>();    
        
        for(Contact con : conList){
            sfConactMap.put(con.FirstName+con.LastName, con);
            conIds.add(con.Id);
            Map<String, Object> contactJson = new Map<String, Object>();
            List<Map<String, String>> namesList = new List<Map<String, String>>();
            Map<String, String> nameMap = new Map<String, String>();
            nameMap.put('familyName', con.LastName);
            nameMap.put('givenName', con.FirstName);
            namesList.add(nameMap);
            contactJson.put('names', namesList); 
            
            List<Map<String, String>> emailList = new List<Map<String, String>>();
            Map<String, String> emailMap = new Map<String, String>();
            emailMap.put('value', con.Email);
            emailList.add(emailMap);
            if(con.Email != null)
                contactJson.put('emailAddresses',emailList);
            
            List<Map<String, String>> phoneList = new List<Map<String, String>>();
            Map<String, String> phoneMap = new Map<String, String>();
            phoneMap.put('value', con.Phone);
            phoneList.add(phoneMap);
            if(con.Phone != null)
                contactJson.put('phoneNumbers',phoneList);
            
            Map<String, Map<String, Object>> contactJson2 = new Map<String, Map<String, Object>>();
            contactJson2.put('contactPerson', contactJson);
            conactList.add(contactJson2);
        }
        
        Map<String, List<Map<String, Map<String, Object>>>> gConList2 = new Map<String, List<Map<String, Map<String, Object>>>>();
        gConList2.put('contacts', conactList);
        String body = JSON.serialize(gConList2);
        body = body.removeEnd('}') + ',"readMask": "names","sources":["READ_SOURCE_TYPE_CONTACT"]}';
        req.setBody(body);
        
        req.setHeader('Content-Type','application/json');
        req.setMethod('POST');
        req.setTimeout(60 * 1000);
        HttpResponse response = http.send(req);
        System.debug('response====='+response);
        System.debug('response body====='+response.getBody());
        if(response.getStatusCode() == 200){
            Map<String,Object> responeMap=(Map<String,Object>)JSON.deserializeUntyped(response.getBody());
            List<Object> createdPeopleList = (List<Object>) responeMap.get('createdPeople');
            
            for(Object obj : createdPeopleList){    
                Map<String,Object> gcon = (Map<String,Object>) obj;
                Map<String,Object> gcon2 = (Map<String,Object>) gcon.get('person');
                List<Object> namesLists = (List<Object>) gcon2.get('names');
                Map<String,Object> record = (Map<String,Object>) namesLists[0];
                String keyword = (String) record.get('givenName');
                keyword += (String) record.get('familyName');
                if(sfConactMap.keySet().contains(keyword)){
                    Contact conObj = sfConactMap.get(keyword);
                    System.debug('Contact get fron response=='+ conObj);
                    conObj.ExternalSourceId__c = (String) gcon2.get('resourceName');
                    conObj.etag__c = (String) gcon2.get('etag');
                    updateGConacts.add(conObj);
                }   
            }
        }
        if(!updateGConacts.isEmpty()){
            GoogleApiQueueable.isDisableTrigger = true;
            update updateGConacts;
            System.debug('updated record');
            GoogleApiQueueable.isDisableTrigger = false;
        }
    }
    
    public static void updateContact(Set<Id> conIdSets){
        List<Contact> conList = [SELECT Id, FirstName, LastName, Email, Phone, ExternalSourceId__c, etag__c FROM contact WHERE Id IN :conIdSets];
        updateContact(conList);
    }
    
    public static void updateContact(List<Contact> contactList){
        Map<String, Contact> sfConactMap = new Map<String, Contact>();
        List<Contact> updateGConacts = new List<Contact>();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String body = '{"contacts":{';
        for(Contact con : contactList){
            sfConactMap.put(con.ExternalSourceId__c, con);
            body += '"'+ con.ExternalSourceId__c +'":{"etag":"'+con.etag__c+'","names":[{"familyName":"'+con.LastName +'","givenName":"'+con.FirstName+'"}]';
            if(con.Phone != null)
                body += ',"phoneNumbers":[{"value": "'+ con.Phone +'"}]';
            if(con.Email != null)
                body += ',"emailAddresses":[{"value": "'+ con.Email +'"}]';
            body += '},';
        }
        body = body.removeEnd(',');
        body += '},"readMask": "names","updateMask": "names,emailAddresses,phoneNumbers","sources":["READ_SOURCE_TYPE_CONTACT"]}';
        req.setBody(body);  
        req.setEndpoint('callout:Connectsalesforces' +'/v1/people:batchUpdateContacts?sources=READ_SOURCE_TYPE_CONTACT');    
        req.setHeader('Content-Type','application/json');
        req.setMethod('POST');
        HttpResponse response = http.send(req);           
        System.debug('response=== '+response.getBody());
        if(response.getStatusCode() == 200){
            Map<String,Object> responeMap=(Map<String,Object>)JSON.deserializeUntyped(response.getBody());
            Map<String,Object> createdPeopleList =(Map<String,Object>) responeMap.get('updateResult');
            
            for(Object obj : createdPeopleList.keySet()){    
                Map<String,Object> gcon = (Map<String,Object>) createdPeopleList.get((String) obj);
                Map<String,Object> gcon2 = (Map<String,Object>) gcon.get('person');
                String resourceName  =(String) gcon2.get('resourceName');
                if(sfConactMap.keySet().contains(resourceName)){
                    Contact conObj = sfConactMap.get(resourceName);
                    conObj.etag__c = (String) gcon2.get('etag');
                    updateGConacts.add(conObj);
                }   
            }
        }
        
        if(!updateGConacts.isEmpty()){
            GoogleApiQueueable.isDisableTrigger = true;
            update updateGConacts;
            GoogleApiQueueable.isDisableTrigger = false; 
        }
        
    }
}