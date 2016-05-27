/*
*   Settings class to expose GL report codes
*
*   Luis Valenzuela 2/03/2013
*/
public with sharing class GlSettings 
{
    public static String actualIntLabRepCode        { get{ refreshConfig(); return actualIntLabRepCode; } }         // 63100
    public static String actualSubFeeRepCode        { get{ refreshConfig(); return actualSubFeeRepCode; } }         // 63010
    public static String actualSubExpRepCode        { get{ refreshConfig(); return actualSubExpRepCode; } }         // 63015
    public static String actualExpRepCode           { get{ refreshConfig(); return actualExpRepCode; } }            // 635*
    public static String actualPassThruRepCode      { get{ refreshConfig(); return actualPassThruRepCode; } }       // 63011
    
    public static String billedProfFeeRepCode       { get{ refreshConfig(); return billedProfFeeRepCode; } }        // 10500
    public static String billedMsProfFeeRepCode     { get{ refreshConfig(); return billedMsProfFeeRepCode; } }      // 10000
    public static String billedMsAdminRepCode       { get{ refreshConfig(); return billedMsAdminRepCode; } }        // 11000
    public static String billedMsDbRepCode          { get{ refreshConfig(); return billedMsDbRepCode; } }           // 11100
    public static String billedMiscAdjRepCode       { get{ refreshConfig(); return billedMiscAdjRepCode; } }        // 11999
    public static String billedExpRepCode           { get{ refreshConfig(); return billedExpRepCode; } }            // 12000
    public static String billedPassThruRepCode      { get{ refreshConfig(); return billedPassThruRepCode; } }       // 13000
    public static String billedDeferRevRepCode      { get{ refreshConfig(); return billedDeferRevRepCode; } }       // 76500
    public static String billedAccrIncRepCode       { get{ refreshConfig(); return billedAccrIncRepCode; } }        // 75000
    
    public static String authIntLabRepCode          { get{ refreshConfig(); return authIntLabRepCode; } }           // 33101
    public static String authSubFeeRepCode          { get{ refreshConfig(); return authSubFeeRepCode; } }           // 20000
    public static String authSubExpRepCode          { get{ refreshConfig(); return authSubExpRepCode; } }           // 20100
    public static String authExpRepCode             { get{ refreshConfig(); return authExpRepCode; } }              // 22*
    public static String authPassThruRepCode        { get{ refreshConfig(); return authPassThruRepCode; } }         // 20300
    public static String authSubFeeInvNotRecRepCode { get{ refreshConfig(); return authSubFeeInvNotRecRepCode; } }  // 75710
    public static String authSubExpInvNotRecRepCode { get{ refreshConfig(); return authSubExpInvNotRecRepCode; } }  // 75715
    public static String authPassThruNotRecRepCode  { get{ refreshConfig(); return authPassThruNotRecRepCode; } }   // 75711
    
    public static map<String, String> rptToGlMap { get{ refreshConfig(); return rptToGlMap; } } 
    
    private static boolean refreshSettingsFlag = true;
    private static boolean generatingFlag = false;
    
    // Refresh method to bring back config from the Env if not already done in this Ex Context
    public static void refreshConfig()
    {
        if( refreshSettingsFlag && !generatingFlag )
        {
            GLAccountSettings__c glAccSettingsInst = GLAccountSettings__c.getInstance();
            if(null != glAccSettingsInst )
            {
                System.Debug(System.Logginglevel.INFO, 'Refreshing Config from Env.');
                                                                    
                actualIntLabRepCode         = glAccSettingsInst.actualIntLabRepCode__c;             // 63100  
                actualSubFeeRepCode         = glAccSettingsInst.actualSubFeeRepCode__c;             // 63010
                actualSubExpRepCode         = glAccSettingsInst.actualSubExpRepCode__c;             // 63015
                actualExpRepCode            = glAccSettingsInst.actualExpRepCode__c;                // 635*
                actualPassThruRepCode       = glAccSettingsInst.actualPassThruRepCode__c;           // 63011
                billedProfFeeRepCode        = glAccSettingsInst.billedProfFeeRepCode__c;            // 10500
                billedMsProfFeeRepCode      = glAccSettingsInst.billedMsProfFeeRepCode__c;          // 10000
                billedMsAdminRepCode        = glAccSettingsInst.billedMsAdminRepCode__c;            // 11000
                billedMsDbRepCode           = glAccSettingsInst.billedMsDbRepCode__c;               // 11100
                billedMiscAdjRepCode        = glAccSettingsInst.billedMiscAdjRepCode__c;            // 11999
                billedExpRepCode            = glAccSettingsInst.billedExpRepCode__c;                // 12000
                billedPassThruRepCode       = glAccSettingsInst.billedPassThruRepCode__c;           // 13000
                billedDeferRevRepCode       = glAccSettingsInst.billedDeferRevRepCode__c;           // 76500
                billedAccrIncRepCode        = glAccSettingsInst.billedAccrIncRepCode__c;            // 75000
                authIntLabRepCode           = glAccSettingsInst.authIntLabRepCode__c;               // 33101
                authSubFeeRepCode           = glAccSettingsInst.authSubFeeRepCode__c;               // 20000
                authSubExpRepCode           = glAccSettingsInst.authSubExpRepCode__c;               // 20100
                authExpRepCode              = glAccSettingsInst.authExpRepCode__c;                  // 22*
                authPassThruRepCode         = glAccSettingsInst.authPassThruRepCode__c;             // 20300
                authSubFeeInvNotRecRepCode  = glAccSettingsInst.authSubFeeInvNotRecRepCode__c;      // 75710
                authSubExpInvNotRecRepCode  = glAccSettingsInst.authSubExpInvNotRecRepCode__c;      // 75715
                authPassThruNotRecRepCode   = glAccSettingsInst.authPassThruNotRecRepCode__c;       // 75711
                
                generatingFlag = true;
                
                rptToGlMap = new map<String,String> {   actualIntLabRepCode => null,
                                                        actualSubFeeRepCode => null, 
                                                        actualSubExpRepCode => null,  
                                                        actualExpRepCode => null, 
                                                        actualPassThruRepCode => null,
                                                        billedProfFeeRepCode => null, 
                                                        billedMsProfFeeRepCode => null, 
                                                        billedMsAdminRepCode => null,  
                                                        billedMsDbRepCode => null,  
                                                        billedMiscAdjRepCode => null, 
                                                        billedExpRepCode => null, 
                                                        billedPassThruRepCode => null,
                                                        billedDeferRevRepCode => null, 
                                                        billedAccrIncRepCode => null, 
                                                        authIntLabRepCode => null, 
                                                        authSubFeeRepCode => null, 
                                                        authSubExpRepCode => null, 
                                                        authExpRepCode => null, 
                                                        authPassThruRepCode => null, 
                                                        authSubFeeInvNotRecRepCode => null,
                                                        authSubExpInvNotRecRepCode => null, 
                                                        authPassThruNotRecRepCode => null };
    
    
                // Special condition as Expenses run over multiple GL codes so aggreagate all 22*** GL codes, first replace * with
                // % necessary for SOQL like query
                String actExpenseGlWildCard = actualExpRepCode.replace('*', '%');
                String authExpenseGlWildCard = authExpRepCode.replace('*', '%');
                list<c2g__codaGeneralLedgerAccount__c> dbGLs = [ Select id, 
                                                                        c2g__ReportingCode__c
                                                                   from c2g__codaGeneralLedgerAccount__c
                                                                  where ( c2g__ReportingCode__c IN :rptToGlMap.keySet() 
                                                                            OR
                                                                          c2g__ReportingCode__c like :actExpenseGlWildCard
                                                                          	OR
                                                                          c2g__ReportingCode__c like :authExpenseGlWildCard )];
                // Log.debug(dbGLs); OK here
                for(c2g__codaGeneralLedgerAccount__c gl : dbGLs)
                {
                    // Explicit GL code
                    if( rptToGlMap.containsKey( gl.c2g__ReportingCode__c ))
                    {
                        rptToGlMap.put(gl.c2g__ReportingCode__c , String.valueOf(gl.Id));
                    }
                    // Actual Expense group
                    else if( gl.c2g__ReportingCode__c.startsWith( actExpenseGlWildCard.substringBefore('%')) )
                    {
	                    // build comma separated list if 15 digit ids
	                    if( rptToGlMap.get(actualExpRepCode) == null )
	                    {
	                        rptToGlMap.put( actualExpRepCode , String.valueOf(gl.Id).left(15) );
	                    }
	                    else
	                    {
	                        rptToGlMap.put( actualExpRepCode , rptToGlMap.get(actualExpRepCode) +','+ ((String) (gl.Id)).substring(0,15)  );
	                    }
                    }
                    // Authorised Expense group
                    else if( gl.c2g__ReportingCode__c.startsWith( authExpenseGlWildCard.substringBefore('%')) )
                    {
	                    // build comma separated list if 15 digit ids
	                    if( rptToGlMap.get(authExpRepCode) == null )
	                    {
	                        rptToGlMap.put( authExpRepCode , String.valueOf(gl.Id).left(15) );
	                    }
	                    else
	                    {
	                        rptToGlMap.put( authExpRepCode , rptToGlMap.get(authExpRepCode) +','+ ((String) (gl.Id)).substring(0,15)  );
	                    }
                    }
                }
				
				Log.Debug(rptToGlMap);
                // Settings are cached 
                generatingFlag = false;
                refreshSettingsFlag = false;
            }
        }
    }
    
    public static void resetConfig()
    {
        refreshSettingsFlag = true;
    }   
    
}