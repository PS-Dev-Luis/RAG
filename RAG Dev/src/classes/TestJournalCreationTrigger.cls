/**
*   TestJournalCreationTrigger
*	============================
*	Test class for changes made as part of CD0387 associated with Journal creation as a result of a Project Approval.  
* 	For each Project that is approved a journal shall be created and the new Journal Lines added to debit and credit
*	the associated General Ledger Accounts that are identified through Custom Settings.
* 	 
*	Luis Valenzuela 5/03/2013
*/
@isTest (seeAllData = true)
public with sharing class TestJournalCreationTrigger 
{

	/**
	* 	TEST 1 : testSubFeeJournalEntry 
	*	Test creation of Journal after insert of project with subscontractor fees, relies on approval  
	*	process created to set generate_journal field on the Project.   
	* 	===============================================================================================
	*	start conditions 	- project with a subcontractor fee, set for approval
	*	action 				- Project approved
	*	end state 			- New Journal created with a line item for Subcontractor Fees. 
	*/	
	@isTest (seeAllData = true)
	public static void testSubFeeJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 1');
		opp.Subcontractor_Labour_Cost__c = 10;
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 1' );
		project.pse__Opportunity__c = opp.id;
		project.pse__Is_Active__c = true;
		insert project;
		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/ 
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );	
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(project), 'Journal for Subcontractor Fees failed.' );	
	} // End of Test 1	


	/**
	* 	TEST 2 : testSubExpJournalEntry
	*	Test creation of Journal after insert of project with subcontractor expenses, relies on approval  
	*	process created to set generate_journal field on the Project.   
	* 	============================================================================================
	*	start conditions 	- project with a subcontractor expence, set for approval
	*	action 				- Project approved
	*	end state 			- New Journal created with a line item for Subcontractor Expenses
	*/	
	@isTest (seeAllData = true)
	public static void testSubExpJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
		// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 2');
		opp.Subcontractor_Expenses__c = 20;
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 2' );
		project.pse__Opportunity__c = opp.id;
		insert project;
		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );			
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(project) , 'Journal for Subcontractor Expenses failed.' );
	} // End of Test 2


	/**
	* 	TEST 3 : testPassThruCostJournalEntry
	*	Test creation of Journal after insert of project with Passed through cost, relies on approval  
	*	process created to set generate_journal field on the Project.  
	* 	============================================================================================
	*	start conditions 	- project with a passed through cost, set for approval
	*	action 				- Project approved
	*	end state 			- New Journal created with a line item for Passed through cost
	*/	
	@isTest (seeAllData = true)
	public static void testPassThruCostJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 3');
		opp.Pass_Through_Costs__c = 30;
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 3' );
		project.pse__Opportunity__c = opp.id;
		insert project;
		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );			
	
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(project), 'Journal for Pass through costs failed. ' );
	} // End of Test 3


	/**
	* 	TEST 4 : testAllJournalEntry
	*	Test creation of Journal after update of project with Passed through cost, relies on approval  
	*	process created to set generate_journal field on the Project. 
	* 	============================================================================================
	*	start conditions 	- project with a passed all values, set for approval
	*	action 				- Project approved
	*	end state 			- New Journal created with a line item for Passed through cost
	*/	
	@isTest (seeAllData = true)
	public static void testAllJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 4');
		opp.Subcontractor_Labour_Cost__c = 15;
		opp.Subcontractor_Expenses__c = 25;
		opp.Pass_Through_Costs__c = 35;
		insert opp;
		// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 4' );
	 	project.pse__Opportunity__c = opp.id;
	 	insert project;

		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );		
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(project), 'Journal creation failed when attempting to create all.' );
	} // End of Test 4
		
	
	/**
	* 	TEST 5 : testInternalProjJournalEntry 
	*	Test creation of Journal after insert of internal project relies on approval  
	*	process created to set generate_journal field on the Project.   
	* 	===============================================================================================
	*	start conditions 	- internal project
	*	action 				- Project approved
	*	end state 			- No Journals created. 
	*/	
	@isTest (seeAllData = true)
	public static void testInternalProjJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 1');
		opp.Subcontractor_Labour_Cost__c = 10;
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 1' );
		project.pse__Opportunity__c = opp.id;
		project.pse__Is_Active__c = true;
		project.is_internal_project__c = true;
		insert project;
		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/ 
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );	
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(project), 'Journal created for internal project.' );	
	} // End of Test 1	



	/**
	* 	TEST 6 : testTimeCardJournalEntry
	*	Test creation of Journal after approval of Timecard, relies on approval process created to 
	*	set generate_journal field on the timecard.
	* 	============================================================================================
	*	start conditions 	- timecard set for approval
	*	action 				- timecard approved
	*	end state 			- New Journal created with a line item for time card charge
	*/	
	@isTest (seeAllData = true)
	public static void testTimeCardJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 5');
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 5' );
		project.pse__Opportunity__c = opp.id;
		insert project;
	  	// Create Resource 
	  	Contact resource = TestHelper.setupContact(); 
	  	insert resource;
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
	  	List<pse__Timecard__c> timecardSplits = [ 	 SELECT Id,
										           			pse__total_billable_amount__c
												       FROM	pse__Timecard__c
												      WHERE pse__Timecard_Header__c = :timeCardHdr.Id];
		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(timeCardHdr) 
								? TestApprovalHelper.approveObj(timeCardHdr) 
									: false );			
		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(timeCardHdr), 'Journal creation failed when attempting to approve Timecard.' );
	} // End of Test 3
	

	/**
	* 	TEST 7 : MiscAdjJournalEntry
	*	Test creation of Journal after approval of Miscellaneous Adjustment, approval process not implemented
	*	action fired by setting the generate_Journal flag on project.
	* 	============================================================================================
	*	start conditions 	- Misc Adj set for approval
	*	action 				- Misc Adj GenerateJournal flag set
	*	end state 			- New Journal created with a line item for misc Adj charge charge
	*/	
	@isTest (seeAllData = true)
	public static void MiscAdjJournalEntry()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		/*++++++++++++++++++ Setup ++++++++++++++++++++++++*/
	 	// Create a Opp for approval.
	 	opportunity opp = TestHelper.setupOpportunity('Test Opp 5');
		insert opp;
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test Project 5' );
		project.pse__Opportunity__c = opp.id;
		insert project;
	 	// Create a Misc Asjtment for approval.
	 	pse__Miscellaneous_Adjustment__c miscAdj = TestHelper.setupMiscAdj( project.id );
		insert miscAdj;

		
		test.startTest();
		/*++++++++++++++++++ Approval action ++++++++++++++++++++++++*/
		// If submit succeeds try and approve else set to false without approval attempt		
		miscAdj.ffps_0387__Generate_Journal__c = true;
		update miscAdj;

		test.stopTest();
		/*++++++++++++++++++ Assertion ++++++++++++++++++++++++*/
		System.assert( checkJournals(miscAdj), 'Journal creation failed when attempting to approve Miscellaneous Adjustment.' );
	} // End of Test 3
	


	

	////////////////////////////////////////////////////////////////////
	// Utility method to do the Journal checking
	private	static boolean checkJournals( pse__Proj__c project)
	{
		boolean testResult = true;
		pse__Proj__c dbProj = [ Select 	id, 
										CurrencyIsoCode,
										name,
										is_internal_project__c,
										Subcontractor_Labour_Cost_2__c,
										Calculated_Subcontractor_Labour_Cost__c,
									 	Subcontractor_Expenses_2__c,
									 	Pass_Through_Costs__c,
										(Select c2g__Journal__c,  
											 	calculated_charge2__c,
												c2g__Value__c,
												c2g__GeneralLedgerAccount__c, 
												c2g__LineDescription__c
								   		   From ffpsai__JournalLineItems__r) 
							   	  From 	pse__Proj__c 
							  	 where 	Id = :project.Id];

		map <String, c2g__codaJournalLineItem__c> rtrnJourns = new map <String, c2g__codaJournalLineItem__c>();
		for(  c2g__codaJournalLineItem__c jornLin : dbProj.ffpsai__JournalLineItems__r )
		{
			rtrnJourns.put(jornLin.c2g__LineDescription__c, jornLin);
		}

		if( dbProj.is_internal_project__c )
		{
			// No journals created for internal projects
			system.assert(rtrnJourns.isEmpty(), 'Journals should not be created for internal project.');
			return true;					  	 
		}

		Log.debug('Returned Journals for project : ' + dbProj.name);
		Log.debug( rtrnJourns );							
		
		// Get the dynamic fields 
		decimal subCosts = dbProj.Subcontractor_Labour_Cost_2__c != null ? dbProj.Subcontractor_Labour_Cost_2__c : 0.00 ;
		decimal subFees = dbProj.Calculated_Subcontractor_Labour_Cost__c != null ? dbProj.Calculated_Subcontractor_Labour_Cost__c : 0.00 ;
		decimal subFeeConverted = CurrencyHelper.convertToHome( subFees, dbProj.CurrencyIsoCode );
		decimal subExpenses = 	dbProj.Subcontractor_Expenses_2__c != null ? dbProj.Subcontractor_Expenses_2__c : 0.00 ;
		decimal passThruCosts = dbProj.Pass_Through_Costs__c != null ? dbProj.Pass_Through_Costs__c : 0.00 ;
		
		// If all values are zero then fail test
		log.debug(project);
		if( (subFees == 0.0) && ( subExpenses == 0.0 ) && (passThruCosts == 0.0) ) testResult = false;
		// If the project contains a value for Subcontractor Fees, check to make sure the correct Journal Entries have been created
		if ( testResult && subFees != 0.0 )
		{
			testResult = 	( -subCosts == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_CRED ).c2g__Value__c ) 
								&&
		 					( subCosts == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_DEBIT).c2g__Value__c ) 
		 						&&
				 			( -subFeeConverted == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_CRED ).calculated_charge2__c ) 
								&&
		 					( subFeeConverted == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_DEBIT).calculated_charge2__c ) 
		 						&&
				 			( CustomSettings.subContractorFeeCreditGLid 
				 				== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_CRED ).c2g__GeneralLedgerAccount__c ) 
				 				&&
						 	(  CustomSettings.subContractorFeeDebitGLid
						 		== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_DEBIT ).c2g__GeneralLedgerAccount__c );
			Log.debug('subFees test result = ' + testResult );		
		}
		// If the project contains a value for Subcontractor Exp, check to make sure the correct Journal Entries have been created
		if ( testResult && subExpenses != 0.0 )
		{
			testResult = 	( -subExpenses == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_CRED ).c2g__Value__c ) 
								&&
		 					( subExpenses == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_DEBIT).c2g__Value__c ) 
		 						&&
				 			( CustomSettings.subContractorExpenseCreditGLid 
				 				== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_CRED ).c2g__GeneralLedgerAccount__c ) 
				 				&&
						 	(  CustomSettings.subContractorExpenseDebitGLid
						 		== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_DEBIT).c2g__GeneralLedgerAccount__c );
			Log.debug('subExpenses test result = ' + testResult );		
		}
		// If the project contains a value for pass through costs, check to make sure the correct Journal Entries have been created
		if ( testResult && passThruCosts != 0.0 )
		{
			testResult = 	( -passThruCosts == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_CRED ).c2g__Value__c ) 
								&&
		 					( passThruCosts == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_DEBIT).c2g__Value__c ) 
		 						&&
				 			( CustomSettings.passThroughCostsCreditGLid 
				 				== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_CRED ).c2g__GeneralLedgerAccount__c ) 
				 				&&
						 	(  CustomSettings.passThroughCostsDebitGLid
						 		== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_DEBIT).c2g__GeneralLedgerAccount__c );
			Log.debug('passThruCosts test result = ' + testResult );		
		}
		return testResult;				
	}
	
	private	static boolean checkJournals( pse__Timecard_Header__c timecardHdr)
	{
		boolean testResult = true;
		pse__Proj__c dbProj = [ Select 	id, 
										CurrencyIsoCode,
										name,
										is_internal_project__c,
										(Select c2g__Journal__c,   
												c2g__Value__c,
												calculated_charge2__c,
												c2g__Dimension1__c,
												c2g__Dimension2__c,
												c2g__Dimension3__c,
												c2g__Dimension4__c,
												c2g__GeneralLedgerAccount__c, 
												c2g__LineDescription__c 
								   		   From ffpsai__JournalLineItems__r) 
							   	  From 	pse__Proj__c 
							  	 where 	Id = :timecardHdr.pse__Project__c];
	
		map <String, c2g__codaJournalLineItem__c> rtrnJourns = new map <String, c2g__codaJournalLineItem__c>();
		for(  c2g__codaJournalLineItem__c jornLin : dbProj.ffpsai__JournalLineItems__r )
		{
			rtrnJourns.put( jornLin.c2g__LineDescription__c.substringAfter(':').trim() , jornLin);
		}

		if( dbProj.is_internal_project__c )
		{
			// No journals created for internal projects
			system.assert(rtrnJourns.isEmpty(), 'Journals should not be created for internal project.');
			return true;					  	 
		} 
		else
		{
			// No Journals created
			system.assert(rtrnJourns.isEmpty() != true, 'No journals created for project.');
		}

		Log.debug('Returned Journals for project : ' + dbProj.name);
		Log.debug( rtrnJourns );							

		pse__Timecard_Header__c dbTimecard = [	Select 	CurrencyIsoCode,
														pse__Total_Billable_Amount__c, 
													 	pse__Total_Hours__c,
														pse__Cost_Rate_Amount__c
												   from pse__Timecard_Header__c 
												  where id = :timecardHdr.id ];
		decimal timecardCost = dbTimecard.pse__Total_Hours__c * dbTimecard.pse__Cost_Rate_Amount__c;
		decimal timecardCharge = CurrencyHelper.convertToHome( dbTimecard.pse__Total_Billable_Amount__c, dbTimecard.CurrencyIsoCode);
		
		testResult = 	( -timecardCost == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_CRED ).c2g__Value__c ) 
							&&
	 					( timecardCost == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_DEBIT ).c2g__Value__c ) 
	 						&&
			 			( -timecardCharge == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_CRED ).calculated_charge2__c ) 
							&&
	 					( timecardCharge == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_DEBIT ).calculated_charge2__c ) 
	 						&&
			 			( CustomSettings.timecardCreditGLid 
			 				== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_CRED ).c2g__GeneralLedgerAccount__c ) 
			 				&&
					 	(  CustomSettings.timecardDebitGLid
					 		== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_TIMECARD_DEBIT ).c2g__GeneralLedgerAccount__c );
		return testResult;
	}

	private	static boolean checkJournals( pse__Miscellaneous_Adjustment__c miscAdj)
	{
		boolean testResult = true;
		pse__Proj__c dbProj = [ Select 	id, 
										CurrencyIsoCode,
										name,
										is_internal_project__c,
										(Select c2g__Journal__c,   
												c2g__Value__c,
												calculated_charge2__c,
												c2g__Dimension1__c,
												c2g__Dimension2__c,
												c2g__Dimension3__c,
												c2g__Dimension4__c,
												c2g__GeneralLedgerAccount__c, 
												c2g__LineDescription__c 
								   		   From ffpsai__JournalLineItems__r) 
							   	  From 	pse__Proj__c 
							  	 where 	Id = :miscAdj.pse__Project__c];
	
		map <String, c2g__codaJournalLineItem__c> rtrnJourns = new map <String, c2g__codaJournalLineItem__c>();
		for(  c2g__codaJournalLineItem__c jornLin : dbProj.ffpsai__JournalLineItems__r )
		{
			rtrnJourns.put( jornLin.c2g__LineDescription__c.substringAfter(':').trim() , jornLin);
		}

		if( dbProj.is_internal_project__c )
		{
			// No journals created for internal projects
			system.assert(rtrnJourns.isEmpty(), 'Journals should not be created for internal project.');
			return true;					  	 
		} 
		else
		{
			// No Journals created
			system.assert(rtrnJourns.isEmpty() != true, 'No journals created for project.');
		}

		Log.debug('Returned Journals for project : ' + dbProj.name);
		Log.debug( rtrnJourns );							

		pse__Miscellaneous_Adjustment__c dbMiscAdj =[Select	CurrencyIsoCode,
															ffpsai__BalancingGLACode__c, 
														 	ffpsai__MiscAdjGLACode__c,
															pse__Amount__c
													   from pse__Miscellaneous_Adjustment__c 
													  where id = :miscAdj.id ];
													  
		decimal misAdjCost = dbMiscAdj.pse__Amount__c;
		decimal miscAdjCharge = CurrencyHelper.convertToHome( dbMiscAdj.pse__Amount__c, dbMiscAdj.CurrencyIsoCode);
		
		testResult = 	( -misAdjCost == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_CRED ).c2g__Value__c ) 
							&&
	 					( misAdjCost == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_DEBIT ).c2g__Value__c ) 
	 						&&
			 			( -miscAdjCharge == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_CRED ).calculated_charge2__c ) 
							&&
	 					( miscAdjCharge == rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_DEBIT ).calculated_charge2__c ) 
	 						&&
			 			( dbMiscAdj.ffpsai__MiscAdjGLACode__c 
			 				== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_CRED ).c2g__GeneralLedgerAccount__c ) 
			 				&&
					 	(  dbMiscAdj.ffpsai__BalancingGLACode__c
					 		== rtrnJourns.get( RefData.JOURNAL_LINE_DESC_MISCADJ_DEBIT ).c2g__GeneralLedgerAccount__c );
		return testResult;
	}
	
}