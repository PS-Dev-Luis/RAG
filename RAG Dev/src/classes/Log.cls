public with sharing class Log 
{
    public static integer counter = 1;
    private static List<String> bufferlogEntries = new List<String>(); 
    private static CustomSettings__c settings = CustomSettings__c.getInstance();

    /* DEBUG */
    public static void debug( String text) 
    { 
        System.debug('\n\n++++++++++++++++++  ' + counter + '  ++++++++++++++++++\n' + text );
        // System.debug( '>>>> ' + counter + ' >>>> ' +text );
        // System.debug(text);
        counter++;
    }
    public static void debug( sObject sObj)
    {
        System.debug(JSON.serializePretty(sObj));   
    }   
    public static void debug( object obj)
    {
        System.debug(JSON.serializePretty(obj));    
    }
    public static void debug( list<sObject> sObjs)
    {
        System.debug(JSON.serializePretty(sObjs));  
    }   
    

    /* WARN */
    public static void warn( String text)
    {
        System.debug( System.Logginglevel.WARN, text);  
    }
    public static void warn( sObject sObj)
    {
        System.debug( System.Logginglevel.WARN, JSON.serializePretty(sObj));    
    }   
    public static void warn( object obj)
    {
        System.debug( System.Logginglevel.WARN, JSON.serializePretty(obj)); 
    }
    public static void warn( list<sObject> sObjs)
    {
        System.debug(System.Logginglevel.WARN, JSON.serializePretty(sObjs));    
    }
    
    /* ERROR */
    public static void error( String text)
    {
        System.debug( System.Logginglevel.ERROR, text); 
    }
    public static void error( sObject sObj)
    {
        System.debug( System.Logginglevel.ERROR, JSON.serializePretty(sObj));   
    }   
    public static void error( object obj)
    {
        System.debug( System.Logginglevel.ERROR, JSON.serializePretty(obj));    
    }
    public static void error( list<sObject> sObjs)
    {
        System.debug(System.Logginglevel.ERROR, JSON.serializePretty(sObjs));   
    }


     /* Buffered Log */
    public static void addLog( String text)
    {
       	if( settings == null || settings.debugEnabled__c == false ) return;    	
        bufferlogEntries.add( '\n >> ' + text );
    }
    public static void addLog( sObject sObj)
    {
       	if( settings == null || settings.debugEnabled__c == false ) return;    	
        bufferlogEntries.add( JSON.serializePretty(sObj) );   
    }   
    public static void addLog( object obj)
    {
       	if( settings == null || settings.debugEnabled__c == false ) return;    	
        bufferlogEntries.add( JSON.serializePretty(obj) );    
    }
    public static void addLog( list<sObject> sObjs)
    {
       	if( settings == null || settings.debugEnabled__c == false ) return;    	
        bufferlogEntries.add( JSON.serializePretty(sObjs) );   
    }

    public static list<String> getLog()
    {
        return bufferlogEntries;
    }
    
    public static String getLogAsString()
    {
    	string logString = '';
    	for(String logEntry : bufferlogEntries)
    	{
    		logString += logEntry + '<br/><br/>';
    	}
        return logString;
    }
    
    public static void outputLog()
    {
    	if( settings == null || settings.debugEnabled__c == false ) return;    	
    	String errorOutput = '';
        for( String errLog : bufferlogEntries )
        {
	        errorOutput += errLog + '\n\n';
        }
        system.debug( errorOutput );
        printFFALog();
    }
        
 
     /* FFA Log */
    public static void printFFALog()
    {
  		String errorString = '\n\n++++++++++++++++++ FFA Log ++++++++++++++++++\n';

    	for(String error : c2g.CODAExtensionContext.getErrorMessages())
        {
            errorString += error +' - ';
        }
        System.debug( errorString );   
    }
    public static String getFFALog()
    {
  		String errorString = ''; 
    	for(String error : c2g.CODAExtensionContext.getErrorMessages())
        {
            errorString += error +' - ';
        }
        return errorString;   
    }
    
    
    /**
     * Send success/fail email to user who requested the action
     **/
    public static void sendDebugEmail()
    {
    	if( settings == null || settings.debugEnabled__c == false 
    			|| settings.debugEmail__c == null || settings.debugEmail__c == '')
    	return;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
        String body = getLogAsString() + '<br/><br/>' + getFFALog();
        mail.setSubject( 'FinancialForce debug from org '+ AppContext.COMPANY_NAME 
        					+ ' : org: ' + UserInfo.getOrganizationName() + ' (' + UserInfo.getOrganizationId() + ')' );
        
        String rootUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        rootUrl = rootUrl.replace( 'http://', 'https://' );
        
        mail.setHtmlBody( body );
        mail.setToAddresses( new String[] { settings.debugEmail__c } ); 
        Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
    }
    
    
    static testmethod void testCoverage()
    {
        Log.debug('test');  
        Log.warn('test');   
        Log.error('test');  
        Log.addLog('test');  
        Opportunity opp = new Opportunity();
        Log.debug(opp); 
        Log.warn(opp);  
        Log.error(opp);
        Log.addLog(opp);
        list<Opportunity> lstOpps = new list<Opportunity>();
        Log.debug(lstOpps); 
        Log.warn(lstOpps);  
        Log.error(lstOpps);
        Log.addLog(lstOpps);

        Log.printFFALog();
        Log.getFFALog();
        Log.outputLog();
        Log.getLog();
        Log.sendDebugEmail();
    }
    
}