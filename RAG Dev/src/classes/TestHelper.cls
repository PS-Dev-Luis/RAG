/**
 *	TestHelper
 *	==========
 *	Helper class to populate test data for scripts.
 *
 *	Luis Valenzuela 20/02/2013
 *
 **/
@isTest (seeAllData = true)
public with sharing class TestHelper 
{

	/* TODO change this value for each DEV org */
	private static final String DEV_ORG_ID = '00Db0000000JqDJEA0';
	private static final String TEST_GLA_ID = 'a0Xb0000001lodS';
	private static final String TEST_REGION_NAME = 'Global';
	private static final String TEST_PRACTICE_NAME = 'Global';
	private static pse__Region__c globalRegionId;
	private static pse__Practice__c globalPracticeId;
	
	public static boolean isDevOrg()
	{
		return userinfo.getOrganizationId() == DEV_ORG_ID;
	}
	
	public static pse__Region__c getGlobalRegionId()
	{
		if(globalRegionId == null)
		{
			// Return Region
			globalRegionId = [ Select Id 
								 From pse__Region__c p
								Where p.Name = :TEST_REGION_NAME LIMIT 1];
			if(globalRegionId == null)
			{
				System.assert(false, 'Global Region not set up or not visible in Dev env, tests failed.');
			}
		}
		return globalRegionId;
	}			


	public static pse__Practice__c getGlobalPracticeId()
	{
		if(globalPracticeId == null)
		{
			// Return Region
			globalPracticeId = [ Select Id 
								   From pse__Practice__c p
								  Where p.Name = :TEST_PRACTICE_NAME LIMIT 1];
			if(globalPracticeId == null)
			{
				System.assert(false, 'Global Practice not set up or not visible in Dev env, tests failed.');
			}
		}
		return globalPracticeId;
	}			


	////////////////////////////////////////////////////////////
	// Data population methods
	/**************/
	/* Assignment */
	public static pse__Assignment__c setupAssignment( Id projectId, Id resourceId, Id scheduleId)
	{
  		// create the Assignment using the normal user Resource
  		return new pse__Assignment__c(	Name = 'Test Assignment',
									    pse__Is_Billable__c = true,
									    pse__Cost_Rate_Amount__c = 10,
									    pse__Bill_Rate__c = 20,
									    CurrencyIsoCode = refData.CURRENCY_DEFAULT,
									    pse__Project__c = projectId,
									    pse__Schedule__c = scheduleId,
									    pse__Resource__c = resourceId);
    }
	/***********/
	/* Contact */
	public static Contact setupContact()
	{
		id EmplRecTypId = [Select Id From RecordType where DeveloperName = 'Employee' and SobjectType = 'Contact'][0].id;
		
		return new Contact(	Email = 'Test_email@company.com',
						    FirstName = 'John',
						    LastName = 'Smith',
						    recordTypeId = EmplRecTypId,
						    CurrencyIsoCode = refdata.CURRENCY_DEFAULT,
						    pse__Is_Resource_Active__c = true,
						    pse__Is_Resource__c = true,
						    pse__Region__c = getGlobalRegionId().Id);
	}
  	/***********/
	/* Journal */
	public static c2g__codaJournal__c setupJournal( String journalRef)
	{
		return new c2g__codaJournal__c( c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
										c2g__JournalDate__c = Date.today(),
										c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
										c2g__Reference__c = journalRef,
										ffgl__DeriveCurrency__c = true,
										ffgl__DerivePeriod__c = true);
	}									
	/***************/
	/* Opportunity */
	public static Opportunity setupOpportunity( String oppName)
	{
		return new opportunity(
			name = oppName,
			CloseDate = date.today().addMonths(1),
			StageName = RefData.OPP_STATUS_PROSPECTING
		);	
	}
	/************/
	/* Project  */
	public static list <pse__Proj__c> setupProjects(integer noOfProjs)
	{
		list<pse__proj__c> retProjs = new list<pse__proj__c>(); 
		for(integer i = 0; i < noOfProjs ; i++)
		{
			retProjs.add( setupProject( 'Test Proj: ' + i ));
		}
		return retProjs;
	}
	
	public static pse__Proj__c setupProject( String projName )
	{
  		return new pse__Proj__c(	Name = projName ,
						    		pse__Region__c = getGlobalRegionId().id,
						    		pse__practice__c = getGlobalPracticeId().id,
							    	pse__Is_Billable__c  = true, 
							    	pse__Closed_for_Time_Entry__c = false,
							    	pse__Closed_for_Expense_Entry__c = false,
							    	pse__Stage__c = RefData.STAGE_IN_PROGRESS,
							    	pse__Is_Active__c = true,
							    	pse__Allow_Timecards_Without_Assignment__c = true,
							    	pse__Allow_Expenses_Without_Assignment__c = true,
							    	CurrencyIsoCode = RefData.CURRENCY_DEFAULT,
							    	pse__Project_Type__c = 'Customer Project',
							    	// pse__Billing_Type__c = billingType,
							    	pse__Expense_Budget__c = 1000,
							    	pse__Start_Date__c = Date.today(),
							    	pse__End_Date__c = Date.today().addMonths(1));
	}
	/********************/
	/* Resource Request */
	public static pse__Resource_Request__c setupResourceRequest()
	{
		return new pse__Resource_Request__c(	pse__Resource_Role__c = refData.RESOURCE_ROLE_ARCHITECT,
												CurrencyIsoCode = RefData.CURRENCY_DEFAULT,
												pse__Start_Date__c = date.today(),
												pse__End_Date__c = date.today().addDays(6),
												pse__SOW_Hours__c = 20,
												pse__Region__c = getGlobalRegionId().Id);	
	}
	/****************/
	/* Schedule		*/
	public static pse__Schedule__c setupSchedule(integer hourPerDay)
	{
  		// build a schedule 
  		return new pse__Schedule__c(  	pse__Start_Date__c = date.today(),
								    	pse__End_Date__c = date.today().addDays(6),
									    pse__Monday_Hours__c = hourPerDay, 
									    pse__Tuesday_Hours__c = hourPerDay,
									    pse__Wednesday_Hours__c = hourPerDay,
									    pse__Thursday_Hours__c = hourPerDay,
									    pse__Friday_Hours__c = hourPerDay,
									    pse__Saturday_Hours__c = 0,
								    	pse__Sunday_Hours__c = 0 );
	}
	/****************/
	/* Timecard		*/
	public static pse__Timecard_Header__c setupTimecardHeader( Id resourceId, Id projectId, Id assignmentId )
	{
		return new pse__Timecard_Header__c(	pse__Resource__c = resourceId,
										    pse__Project__c = projectId,
										    pse__Assignment__c = assignmentId,
										    pse__Milestone__c = null,
										    pse__Start_Date__c = date.today(),
										    pse__End_Date__c = date.today().addDays(6), 
										    pse__Sunday_Hours__c = 0.0,
										    pse__Monday_Hours__c = 7.5,
										    pse__Tuesday_Hours__c = 7.5,
										    pse__Wednesday_Hours__c = 7.5,
										    pse__Thursday_Hours__c = 7.5,
										    pse__Friday_Hours__c = 7.5,
										    pse__Saturday_Hours__c = 0.0,
										    pse__Sunday_Notes__c = 'sunNotes',
										    pse__Monday_Notes__c = 'monNotes',
										    pse__Tuesday_Notes__c = 'tueNotes',
										    pse__Wednesday_Notes__c = 'wedNotes',
										    pse__Thursday_Notes__c = 'thrNotes',
										    pse__Friday_Notes__c = 'friNotes',
										    pse__Saturday_Notes__c = 'satNotes',
										   	pse__Approved__c = false,
										  	pse__Submitted__c = false,
										  	pse__Billable__c = true,
										  	pse__Include_In_Financials__c = true,
										  	pse__Exclude_from_Billing__c = false);
	}
	/********************************/
	/* Miscellaneous Adjustmenr		*/
	public static pse__Miscellaneous_Adjustment__c setupMiscAdj( Id projectId )
	{
		return new pse__Miscellaneous_Adjustment__c(	pse__Amount__c = 500,
													    ffpsai__BalancingGLACode__c = TEST_GLA_ID,
													    ffpsai__MiscAdjGLACode__c = TEST_GLA_ID,
													    pse__Transaction_Category__c = 'Booked Revenue',
													    pse__Description__c = 'Test Misc Adj',
													    pse__Project__c = projectId,
													    ffps_0387__Generate_Journal__c = false,
													    pse__Effective_Date__c = date.today() );
  }


	// End of data Population methods
	////////////////////////////////////////////////////////////
}