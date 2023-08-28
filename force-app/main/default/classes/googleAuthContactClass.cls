/* class Name		: googleAuthContactClass
* Description		: Temporary class to get auth token for updateBulkGcontacts. run googleAuthContactPage vf page to call and get auth token
*/
public with sharing class googleAuthContactClass {
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
    
    public googleAuthContactClass(){       
        code = ApexPages.currentPage().getParameters().get('code');
        if (code != '' && code != null) {
            AccessToken();
            System.debug('inside AccessToken()');
        }
    }
    
    
    public static pagereference connect(){
        System.debug('connect method called');
        String x=OAUTH_CODE_END_POINT_URL+'?scope='+EncodingUtil.urlEncode(SCOPE,'UTF-8')+'&state='+EncodingUtil.urlEncode(STATE,'UTF-8')+'&redirect_uri='+EncodingUtil.urlEncode(REDIRECT_URL,'UTF-8')+'&response_type=code&client_id='+CLIENT_ID;
        pagereference p=new pagereference(x);
        System.debug('p pagereference in line 30');
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
        System.debug('authtoken======='+authtoken); // Used this authtoken in updateBulkGcontacts
        return null;
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