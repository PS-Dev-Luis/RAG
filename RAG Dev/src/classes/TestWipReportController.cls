/**
*	TestWipReportController
*	============================
*	Test class for GenerateWipReport and WipReport VF pages and WipReportController  
*
*	Luis Valenzuela 4/04/2013
*/
public with sharing class TestWipReportController 
{
	public static decimal PROPOSED_INTERNAL_LABOR_COST = 100; 
	public static decimal SUBCONTRACTOR_LABOUR_COST = 200;
	public static decimal SUBCONTRACTOR_EXPENSES = 300;
	public static decimal PASS_THROUGH_COSTS = 400;
	public static decimal PERCENTAGE_SUBFEE_APPLIED = 0.025;
	public static decimal PROPOSED_TOTAL_FEE = 800;
	
	public static String DEBIT_GL_REPCODE = '99999';
	
	public static map<String,Id> lclRptToGlMap;
	public static c2g__codaGeneralLedgerAccount__c debitGLAcc;
			
	
	/** 
	* 	TEST 1 : testGenerateWipReport
	*	Test Generation of WIP report
	* 	==================================================================
	*	start conditions 	- New Project with budget fields populated and Journal lines associated.
	*	action 				- Generate Wip Report using WipReport Controller
	*	end state 			- New WipReport onbject with the correct values populated.
	*/
	@isTest (seeAllData = true)
	public static void testGenerateWipReport()
	{
			// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	  	  
	  	/* ++++++++++++++++ SETUP +++++++++++++++++++ */
	  
	  	opportunity opp = testHelper.setupOpportunity('Test Opp 1');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
//		opp.Proposed_Total_Fee__c 						= PROPOSED_TOTAL_FEE;
		insert opp;
		
		// Populate & insert Project
		pse__Proj__c project = testHelper.setupProject('Test1 Project');
		project.pse__Opportunity__c = opp.Id;
		project.Project_Code__c = 'TST Proj';
		insert project;
		// Create Resource
	  	Contact resource = TestHelper.setupContact(); 
	  	insert resource;
		// Create Resource Request
		pse__Resource_Request__c resReq = testHelper.setupResourceRequest();
		resReq.pse__Opportunity__c = opp.Id;
		insert resReq;
  		// Create Schedule 
	  	pse__Schedule__c schedule = TestHelper.setupSchedule(1);
	  	insert schedule;
		// Create Assignment
	  	pse__Assignment__c assignment = TestHelper.setupAssignment( project.Id, resource.Id, schedule.Id);
	  	insert assignment;
		// Create Timecard
	  	pse__Timecard_Header__c timeCardHdr = TestHelper.setupTimecardHeader( resource.Id, project.Id, assignment.Id);
	  	insert timeCardHdr;
				  
	 	// find the first resulting timecard split
	  	List<pse__Timecard__c> lstTimecardSplits = [ SELECT Id,
												           	pse__total_billable_amount__c
												      FROM	pse__Timecard__c
												     WHERE 	pse__Timecard_Header__c = :timeCardHdr.Id];
	  	pse__Timecard__c timeCard = lstTimecardSplits[0];
	
		setupGlAccounts();	
		
		c2g__codaJournal__c journal = testHelper.setupJournal( 'Test Journal');
		insert journal;
		list <c2g__codaJournalLineItem__c> newJournalLines = new list<c2g__codaJournalLineItem__c>();
		integer lineCount = 0;
		integer lineValue = 10;
		
		// Dimension should be created by trigger after project insert
		c2g__codaDimension3__c projDim = [ Select id from c2g__codaDimension3__c where project__c = :project.id];
		Log.debug('Dimension Found ->');
		Log.debug(projDim);

		Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
		Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
		
		for ( string repCode : GlSettings.rptToGlMap.keyset() )
		{
			if( repCode != GlSettings.authExpRepCode && repCode != GlSettings.actualExpRepCode  )
			{
				// Add Credit


				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__Journal__c = journal.Id,
																		c2g__LineDescription__c = 'WIP Report Journal line',
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = lineValue,
																		calculated_charge2__c = lineValue * 2.5,
																		ffpsai__Project__c = project.Id,
																		c2g__dimension1__c = d1,
																		c2g__dimension2__c = d2,																		
																		c2g__Dimension3__c = projDim.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = GlSettings.rptToGlMap.get(repCode)));
				// Add Debit
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__Journal__c = journal.Id,
																		c2g__LineDescription__c = 'WIP Report Journal line - Debit',
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -lineValue,
																		calculated_charge2__c = -lineValue * 2.5,
																		ffpsai__Project__c = project.Id,
																		c2g__dimension1__c = d1,
																		c2g__dimension2__c = d2,
																		c2g__Dimension3__c = projDim.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = debitGLAcc.Id));
			}
		}
		system.debug( JSON.serializePretty(newJournalLines));
		 
		insert newJournalLines;
		// Post Journal
		c2g.CODAAPICommon_6_0.Context context = new c2g.CODAAPICommon_6_0.Context();
        context.token = EncodingUtil.convertToHex( Crypto.generateDigest('SHA1',
	                		Blob.valueOf('0000000000000000C000000000000046' + UserInfo.getUserId() + 
	                			'PROBABLEMENTE EL MEJOR SOFTWARE DE CONTABILIDAD EN EL MUNDO')));
   		c2g.CODAAPIJournal_6_0.PostJournal( context, c2g.CODAAPICommon.getRef( journal.id, null ) );

		Test.startTest();   		
	 	/* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
		// Instantiate VF page  and Controller to check for errors
		WipReport__c wiprep = new wipReport__c();
		wiprep.project__c = project.id;
		wipRep.snapShotDate__c = Date.today().addDays(7);    	

		PageReference pageRef = Page.WipReportView;
		Test.setCurrentPage(pageRef);
    	ApexPages.StandardController sc = new ApexPages.standardController(wiprep);
    	WipReportController wipRepCtrl = new WipReportController(sc);
		wipRepCtrl.generateWipReport();
   		String testString1 = wipRepCtrl.wipReportDimId;
   		String testString2 = wipRepCtrl.wipReportURL;
   		String testString3 = wipRepCtrl.wipReportGlList;
   		String testString4 = wipRepCtrl.wipReportSnapshotDate;
   		
   		Test.stopTest();
   		
   		/* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
		list <c2g__codaTransactionLineItem__c> lineItems = [ Select Id,
                                                               		c2g__HomeValue__c,
                                                               		calculated_charge2__c, 
                                                                    c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c
                                                               From c2g__codaTransactionLineItem__c 
                                                              where c2g__Dimension3__r.Project__c = :project.Id 
                                                                and c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c in :GlSettings.rptToGlMap.keyset()];
        Log.debug( lineItems );
	}	

	/**
	 * Utility method to initialise GL accounts if not present
	 */
	static void setupGlAccounts()
	{
		list<c2g__codaGeneralLedgerAccount__c> newGlAccs = new list<c2g__codaGeneralLedgerAccount__c>();
		for(String repCode : GlSettings.rptToGlMap.keyset() )
		{
			if( GlSettings.rptToGlMap.get(repCode) == null )
			{
				newGlAccs.add( new c2g__codaGeneralLedgerAccount__c( c2g__ReportingCode__c = repCode, 
																		c2g__Type__c = refData.GL_TYPE_BALANCE, 
																			CurrencyIsoCode = refData.CURRENCY_DEFAULT ));
			}
		}
		// Create a new GL account to dump all the debit journal lines into  
	  	debitGLAcc= new c2g__codaGeneralLedgerAccount__c( c2g__ReportingCode__c = DEBIT_GL_REPCODE, 
															c2g__Type__c = refData.GL_TYPE_BALANCE, 
																CurrencyIsoCode = refData.CURRENCY_DEFAULT);
		newGlAccs.add(debitGLAcc);
		// insert new GL accounts where necessary
		upsert newGlAccs; 
		// Refresh settings to pick up the new ids
		GlSettings.resetConfig();
		GlSettings.refreshConfig(); 				
	}
}