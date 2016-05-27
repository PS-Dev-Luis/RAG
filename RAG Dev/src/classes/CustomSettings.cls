/*
*	Settings class to expose Custom Settings
*
*	Luis Valenzuela 2/03/2013
*/
public with sharing class CustomSettings 
{
	
	
	public static Id subContractorExpenseCreditGLid { get{ refreshConfig(); return subContractorExpenseCreditGLid; } }
	public static Id subContractorExpenseDebitGLid { get{  refreshConfig(); return subContractorExpenseDebitGLid; } }
	public static Id subContractorFeeCreditGLid { get{  refreshConfig(); return subContractorFeeCreditGLid; } }
	public static Id subContractorFeeDebitGLid { get{  refreshConfig(); return subContractorFeeDebitGLid; } }
	public static Id passThroughCostsCreditGLid { get{  refreshConfig(); return passThroughCostsCreditGLid; } }
	public static Id passThroughCostsDebitGLid { get{  refreshConfig(); return passThroughCostsDebitGLid; } }
	public static Id timecardCreditGLid { get{  refreshConfig(); return timecardCreditGLid; } }
	public static Id timecardDebitGLid { get{  refreshConfig(); return timecardDebitGLid; } }
	public static decimal subFeeMultiplier { get{  refreshConfig(); return subFeeMultiplier; } }

	private static boolean refreshSettingsFlag = true;
	
	// Refresh method to bring back config from the Env if not already done in this Ex Context
	public static void refreshConfig()
	{
		if( refreshSettingsFlag )
		{
			CustomSettings__c customSettingsInst = CustomSettings__c.getInstance();
			if(null != customSettingsInst )
			{
				list<String> genLegReportingCodes = new String[] {	customSettingsInst.GLReportCode_SubcontractorExpenseCredit__c,
																	customSettingsInst.GLReportCode_SubcontractorExpenseDebit__c,
																	customSettingsInst.GLReportCode_SubcontractorFeeCredit__c,
																	customSettingsInst.GLReportCode_SubcontractorFeeDebit__c,
																	customSettingsInst.GLReportCode_PassThroughCostCredit__c,
																	customSettingsInst.GLReportCode_PassThroughCostDebit__c,
																	customSettingsInst.GLReportCode_timecardCredit__c,
																	customSettingsInst.GLReportCode_timecardDebit__c };
	
				System.Debug(System.Logginglevel.INFO, 'Refreshing Config from Env.');
				list<c2g__codaGeneralLedgerAccount__c> dbGLs = [ Select 
																		id, 
																		c2g__ReportingCode__c
																	from
																		c2g__codaGeneralLedgerAccount__c
																	where
																		c2g__ReportingCode__c IN :	genLegReportingCodes];	
				
				map<String, Id> rptToGlMap = new map<String,Id>(); 
				for(c2g__codaGeneralLedgerAccount__c gl : dbGLs)
				{
					rptToGlMap.put(gl.c2g__ReportingCode__c , gl.Id);
				}
				
				subContractorExpenseCreditGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_SubcontractorExpenseCredit__c );
				subContractorExpenseDebitGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_SubcontractorExpenseDebit__c );
				subContractorFeeCreditGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_SubcontractorFeeCredit__c );
				subContractorFeeDebitGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_SubcontractorFeeDebit__c );
				passThroughCostsCreditGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_PassThroughCostCredit__c );
				passThroughCostsDebitGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_PassThroughCostDebit__c );
				timecardCreditGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_timecardCredit__c );
				timecardDebitGLid =  rptToGlMap.get( customSettingsInst.GLReportCode_timecardDebit__c );
				subFeeMultiplier = (customSettingsInst.SubContractorFeeMarkup__c == null ? 250 : customSettingsInst.SubContractorFeeMarkup__c );
				
				// Settings are cached 
				refreshSettingsFlag = false;
			}
		}
	}
	
}