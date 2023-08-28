/* class Name		: updateBulkGcontacts
* Description		: class to sync SF with g-contacts for bulk updates.
*/
public class updateBulkGcontacts {
    
    private static String code;  
    public static string authtoken{get;set;}
    public static string bodyprint{get;set;}
    public string phoneNumber{get;set;}
    public static List<googleContactInfo> googleContactInfotList {get; set;}
    private static string CLIENT_SECRET='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';
    private static string CLIENT_ID='731692654244-jkahog3pcn6rh079p463rrdl3is62km0.apps.googleusercontent.com';//Fill as per your registered app settings in google console
    private static string REDIRECT_URL='https://raagvitech137-dev-ed--c.develop.vf.force.com/apex/googleAuthContactPage?core.apexpages.request.devconsole=1';
    private static string OAUTH_TOKEN_URL='https://accounts.google.com/o/oauth2/token';
    private static string OAUTH_CODE_END_POINT_URL='https://accounts.google.com/o/oauth2/auth';
    private static string GRANT_TYPE='grant_type=authorization_code';
    private static string SCOPE='https://www.google.com/m8/feeds';
    private static string STATE='/profile';
    
    public updateBulkGcontacts(){       
        code = ApexPages.currentPage().getParameters().get('code');
        if (code != '' && code != null) {
            AccessToken();
            System.debug('inside AccessToken()');
        }
    }
    
    public static pagereference connect(){
        String x=OAUTH_CODE_END_POINT_URL+'?scope='+EncodingUtil.urlEncode(SCOPE,'UTF-8')+'&state='+EncodingUtil.urlEncode(STATE,'UTF-8')+'&redirect_uri='+EncodingUtil.urlEncode(REDIRECT_URL,'UTF-8')+'&response_type=code&client_id='+CLIENT_ID;
        pagereference p=new pagereference(x);
        return p;
    }
    
    
    public static pagereference AccessToken(){
        System.debug('AccessToken method called');
        string codeparam=apexpages.currentpage().getparameters().get('code');
        Http h = new Http();
        String body='code='+codeparam+'&client_id='+CLIENT_ID+'&client_secret='+CLIENT_SECRET+'&redirect_uri='+REDIRECT_URL+'&'+GRANT_TYPE;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(OAUTH_TOKEN_URL);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        req.setBody(body);
        HttpResponse res = h.send(req);
        getAccessToken getAccessTokenFromGContactApi = (getAccessToken)JSON.deserialize(res.getBody(), getAccessToken.class);     
        authtoken = getAccessTokenFromGContactApi.access_token;
        System.debug('authtoken======='+authtoken);
        return null;
    } 
    
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
        String key = 'AIzaSyCfaCukF1akyPBunr6HfCtzBhSxdepCRiE';
        req.setEndpoint('https://people.googleapis.com/v1/people:batchCreateContacts?sources=READ_SOURCE_TYPE_CONTACT&key=' + key);
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
        
        String authtoken='ya29.a0AfB_byDhdepsxiZCAguDL_WFcu5QtJocudRXmacV6evg0vmC402hRDjw7gsVnRwdXhHlM_vulz3wFmvdTWEbGQAZlbi4tC-LzHX_jPrt2B8WXHmu8v_rMyxDzrqloOj76hNYQ78t3UdV0HydXDJNvGHWU5H1-afoM300j9ZQxqUaCgYKAfkSARISFQHsvYlsIaYb8Gl2BTBS5w-OPEbRkQ0178';
        req.setHeader('Authorization', 'Bearer '+authtoken);
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
        String key = 'AIzaSyCfaCukF1akyPBunr6HfCtzBhSxdepCRiE';
        String authtoken='ya29.a0AfB_byDhdepsxiZCAguDL_WFcu5QtJocudRXmacV6evg0vmC402hRDjw7gsVnRwdXhHlM_vulz3wFmvdTWEbGQAZlbi4tC-LzHX_jPrt2B8WXHmu8v_rMyxDzrqloOj76hNYQ78t3UdV0HydXDJNvGHWU5H1-afoM300j9ZQxqUaCgYKAfkSARISFQHsvYlsIaYb8Gl2BTBS5w-OPEbRkQ0178';
        req.setEndpoint('https://people.googleapis.com/v1/people:batchUpdateContacts?sources=READ_SOURCE_TYPE_CONTACT&key='+key);    
        req.setHeader('Authorization', 'Bearer ' + authtoken);
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
    
    public class getAccessToken {
        public String access_token {get; set;}
        public String token_type {get; set;}
        public String expires_in {get; set;}
        public String scope {get; set;}
        public String jti {get; set;}
    }
    
    public class googleContactInfo {
        public string name{get; set;}
        public List<String> email{get; set;}
        public List<string> phone{get; set;}
        public String photourl{get; set;}
    }
}