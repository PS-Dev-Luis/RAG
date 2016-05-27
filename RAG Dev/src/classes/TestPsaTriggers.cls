/**
*	TestPsaTriggers
*	===============
*	Test class for changes made as part of CD0387 associated with triggers on
* 	Project and Resource Request objects.
*  
*	Luis Valenzuela 19/02/2013 
*
*/
@isTest (seeAllData = true)
public with sharing class TestPsaTriggers 
{
	

	/**
	* 	TEST 1 : testProjectTrigger
	*	Test ProjectTrigger after insert of project
	* 	==================================================================
	*	start conditions 	- 2 resource requests associated with opportunity
	*	action 				- insert of project onto opportunity
	*	end state 			- opp's resource requests are on new project
	*/	
	@isTest (seeAllData = true)
	public static void testInsertProjectTrigger()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		// Populate & insert Opportunity			
		opportunity opp = testHelper.setupOpportunity('Test 1 Opp');
		insert opp;
		
		// Populate Resource Requests
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq1.pse__Opportunity__c = opp.Id;
		resReq2.pse__Opportunity__c = opp.Id;
	
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2};
		Database.SaveResult[] lsr = Database.insert( resReqs , false);
		for (Database.SaveResult sr:lsr)
		{
    		if(!sr.isSuccess()) System.Assert(false, 'Insertion of Resource Requests failed.');
		}
		
		// Populate & insert Project
		pse__Proj__c project = testHelper.setupProject('Test 1 Project');
		project.pse__Opportunity__c = opp.Id;
		insert project;

		// Query updated objects		
		Set<Id> updResReqIds = new Set<Id>();
		for( pse__Resource_Request__c resReq : resReqs )
		{
			updResReqIds.add(resReq.Id);
		}
		
		List<pse__Resource_Request__c> updResReqs = [Select p.Id,  
															p.Name, 
															p.pse__Project__c  
													   From pse__Resource_Request__c p
													  Where p.Id IN :updResReqIds];
		
		// ASSERT that project has been added to resReq
		for( pse__Resource_Request__c resReq : updResReqs )
		{
			System.Assert( (resReq.pse__Project__c == project.Id ), 
				'TestTrigger TEST 1 Failed : Resource Request not updated with project.');
		} 		
	} //  end of TEST1
	
	
	/**
	*	TEST 2 : testResourceRequestPositiveTrigger
	* 	Test ResourceRequestTrigger after insert of a Resource Request
	* 	==============================================================
	*	start conditions 	- 1 Project associated with Opportunity
	*	action 				- insert of Resource Requests onto Opportunity
	*	end state 			- Resource Requests associated with Project 
	*/	
	@isTest (seeAllData = true)
	public static void testResourceRequestPositiveTrigger()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
					
		// Populate & insert opportunity
		opportunity opp = testHelper.setupOpportunity('Test 2 Opp');
		insert opp;
	
		// Populate & insert Project
		pse__Proj__c project = testHelper.setupProject('Test 2 Project');
		project.pse__Opportunity__c = opp.Id;
		insert project;
		
		// Populate Resource Requests
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq1.pse__Opportunity__c = opp.Id;
		resReq2.pse__Opportunity__c = opp.Id;
	
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2};
		Database.SaveResult[] lsr = Database.insert( resReqs , false);
		for (Database.SaveResult sr:lsr)
		{
    		if(!sr.isSuccess()) System.Assert(false, 'Insertion of Resource Reqests failed.');
		}
		
		// Query updated objects
		Set<Id> updResReqIds = new Set<Id>();
		for( pse__Resource_Request__c resReq : resReqs )
		{
			updResReqIds.add(resReq.Id);
		}
		List<pse__Resource_Request__c> updResReqs = [ Select p.Id,  
															 p.Name, 
															 p.pse__Project__c  
														From pse__Resource_Request__c p
													   Where p.Id IN :updResReqIds ];

		// ASSERT that project has been added to resReq
		for( pse__Resource_Request__c resReq : updResReqs )
		{
			System.Assert(resReq.pse__Project__c == project.Id, 
				'TestTrigger TEST 2 Failed : Project not added to Resource Request.' );
		} 		
		
	}// end of TEST2


	/**
	*	TEST 3 : testResourceRequestNegativeTrigger
	* 	Test ResourceRequestTrigger after insert of a Resource Request
	* 	==============================================================
	*	start conditions 	- 2 Projects associated with Opportunity
	*	action 				- insert of Resource Requests onto Opportunity
	*	end state 			- Resource Requests not associated with either Project 
	*/	
	@isTest (seeAllData = true)
	public static void testResourceRequestNegativeTrigger()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
						
		// Populate & insert opportunity
		opportunity opp = testHelper.setupOpportunity('Test 3 Opp');
		insert opp;
	
		// Populate & insert Project
		pse__Proj__c project = testHelper.setupProject('Test 3 Project1');
		pse__Proj__c project2 = testHelper.setupProject('Test 3 Project2');
		project.pse__Opportunity__c = opp.Id;
		project2.pse__Opportunity__c = opp.Id;
		insert project;
		insert project2;
		
		// Populate Resource Requests
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq1.pse__Opportunity__c = opp.Id;
		resReq2.pse__Opportunity__c = opp.Id;
	
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2};
		Database.SaveResult[] lsr = Database.insert( resReqs , false);
		for (Database.SaveResult sr:lsr)
		{
    		if(!sr.isSuccess()) System.Assert(false, 'Insertion of Resource Reqests failed.');
		}
		
		// Query updated objects
		Set<Id> updResReqIds = new Set<Id>();
		for( pse__Resource_Request__c resReq : resReqs )
		{
			updResReqIds.add(resReq.Id);
		}
		
		List<pse__Resource_Request__c> updResReqs = [ Select p.Id,  
															 p.Name, 
															 p.pse__Project__c  
														From pse__Resource_Request__c p
													   Where p.Id IN :updResReqIds ];
		 										
		// ASSERT that project has been added to resReq
		for( pse__Resource_Request__c resReq : updResReqs )
		{
			System.Assert(resReq.pse__Project__c == null,
				'TestTrigger TEST 3 Failed : Project erroneously added to Resource Request.' );
		} 		
	}// end of TEST3 
	


	/**
	* 	TEST 4 : TestCreateTransactionLineItem
	*	Test TransactionLineItem.trigger after insert of txLin
	* 	==================================================================
	*	start conditions 	- Create a Journal with no calcualted charge specified
	*	action 				- Post the Journal to create Transactions
	*	end state 			- The transaction line items should have a populated calculated charge.
	*/	
	@isTest (seeAllData = true)
	public static void TestCreateTransactionLineItem()
	{	
		// Populate & insert Project
		pse__Proj__c project = testHelper.setupProject('Test 4 Project');
		insert project;
		
		// Journal
		c2g__codaJournal__c jrn = new c2g__codaJournal__c( 	CurrencyIsoCode = project.CurrencyIsoCode,
	  														c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
											 				c2g__JournalDate__c = Date.today(),
														 	c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
														 	c2g__Reference__c = 'Test Journal',
															ffgl__DeriveCurrency__c = true,
														 	ffgl__DerivePeriod__c = true);
		insert jrn;
		jrn = [Select id, Name from c2g__codaJournal__c where id = :jrn.id ];
		Log.debug(jrn);

/*
		Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
		Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
		Id d3 = [Select Id from c2g__codaDimension3__c limit 1].Id;		
*/
		// Journal lines
		c2g__codaJournalLineItem__c jrnLin1 = new c2g__codaJournalLineItem__c(	c2g__Journal__c = jrn.Id,
																				c2g__LineDescription__c = 'Test Jrn Lin',
																				c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																				c2g__Value__c = 100,
																				/*c2g__dimension1__c = d1,
																				c2g__dimension2__c = d2,
																				c2g__dimension3__c = d3,*/																					
																				//calculated_charge2__c =	null,
																				ffpsai__Project__c = project.Id,
																				c2g__LineNumber__c = 1,
																				c2g__GeneralLedgerAccount__c = CustomSettings.timecardDebitGLid);

		c2g__codaJournalLineItem__c jrnLin2 = new c2g__codaJournalLineItem__c(	c2g__Journal__c = jrn.Id,
																				c2g__LineDescription__c = 'Test Jrn Lin',
																				c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																				c2g__Value__c = 200,
																				/*c2g__dimension1__c = d1,
																				c2g__dimension2__c = d2,
																				c2g__dimension3__c = d3,*/																					
																				calculated_charge2__c =	50,
																				ffpsai__Project__c = project.Id,
																				c2g__LineNumber__c = 2,
																				c2g__GeneralLedgerAccount__c = CustomSettings.timecardDebitGLid);

		c2g__codaJournalLineItem__c jrnLin3 = new c2g__codaJournalLineItem__c(	c2g__Journal__c = jrn.Id,
																				c2g__LineDescription__c = 'Test Jrn Lin',
																				c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																				c2g__Value__c = -100,
																				/*c2g__dimension1__c = d1,
																				c2g__dimension2__c = d2,
																				c2g__dimension3__c = d3,*/	
																				//calculated_charge2__c =	null,
																				ffpsai__Project__c = project.Id,
																				c2g__LineNumber__c = 3,
																				c2g__GeneralLedgerAccount__c = CustomSettings.timecardCreditGLid);

		c2g__codaJournalLineItem__c jrnLin4 = new c2g__codaJournalLineItem__c(	c2g__Journal__c = jrn.Id,
																				c2g__LineDescription__c = 'Test Jrn Lin',
																				c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																				c2g__Value__c = -200,
																				/*c2g__dimension1__c = d1,
																				c2g__dimension2__c = d2,
																				c2g__dimension3__c = d3,*/																			
																				calculated_charge2__c =	-50,
																				ffpsai__Project__c = project.Id,
																				c2g__LineNumber__c = 4,
																				c2g__GeneralLedgerAccount__c = CustomSettings.timecardCreditGLid);
		// insert new line items																					 	
		list<c2g__codaJournalLineItem__c> jrnLins = new c2g__codaJournalLineItem__c[]{jrnLin1,jrnLin2,jrnLin3,jrnLin4};
		insert jrnLins;
		
		Test.startTest();
		JournalCreationHelper.postJournals(new c2g__codaJournal__c[]{jrn});
		test.stopTest();
			
		list<c2g__codaTransaction__c> txs = [ select Id,
													 c2g__DocumentNumber__c,
													 (Select Id,
							                                 c2g__HomeValue__c, 
							                                 calculated_charge2__c,
							                                 c2g__LineNumber__c
							                            From c2g__TransactionLineItems__r)
									            from c2g__codaTransaction__c
									           where c2g__DocumentNumber__c = :jrn.Name]; 
		for(c2g__codaTransactionLineItem__c txLi : txs[0].c2g__TransactionLineItems__r)
		{
			System.assert( txLi.calculated_charge2__c !=  null && txLi.calculated_charge2__c != 0.0, 'Calculated charge not populated correctly.');
		}
	}
	
	
	
	/**
	* 	TEST 5 : testEmployeeCodeTrigger
	*	Test ContactTrigger after insert of contacts
	* 	==================================================================
	*	action 				- insert a set of contacts
	*	end state 			- Employee number and code set for record type employee
	*/	
	@isTest (seeAllData = true)
	public static void testEmployeeCodeTrigger()
	{
		id EmplRecTypId = [Select Id From RecordType where DeveloperName = 'Employee' and SobjectType = 'Contact'][0].id;
		Contact con1 = new Contact(  recordTypeId = EmplRecTypId, firstName = 'Luis', lastName = 'Valenzuela' );
		Contact con2 = new Contact(  recordTypeId = EmplRecTypId, firstName = 'Eddie', lastName = 'Vedder' );
		Contact con3 = new Contact(  recordTypeId = EmplRecTypId, firstName = 'Bob', lastName = 'Marley' );
		Contact con4 = new Contact(   firstName = 'XXX', lastName = 'XXXXX' );
		
		Contact[] conts = new Contact[]{con1,con2,con3, con4};
		Contact con5 = new Contact(  recordTypeId = EmplRecTypId, firstName = 'Zebra', lastName = 'Zoolander' );
		
		Test.startTest();
		insert conts;
		insert con5;
		Test.stopTest();

		map<id,Contact> contsMap = new map<id,contact>( conts);
		set<id> conIds = contsMap.keySet().clone();
		conIds.add(con5.id);

		list<Contact> dbCons = [ Select RecordType.Name, 
										recordTypeId, 
										employeeCode__c, 
										employeeNumber__c 
								   from Contact 
								  where id in :conIds ];

		map<id,Contact> dbContactMap = new map<id,Contact>(dbCons);						  

		log.debug(dbCons);
		// Ensure that the codes and numbers have been created
		System.assert( dbContactMap.get(con1.id).employeeCode__c != null, 'Employee1 code not created.' ); 
		System.assert( dbContactMap.get(con1.id).employeeNumber__c != null, 'Employee1 number not created.' ); 
		
		System.assert( dbContactMap.get(con2.id).employeeCode__c != null, 'Employee2 code not created.' ); 
		System.assert( dbContactMap.get(con2.id).employeeNumber__c != null, 'Employee2 number not created.' ); 
		
		System.assert( dbContactMap.get(con3.id).employeeCode__c != null, 'Employee3 code not created.' ); 
		System.assert( dbContactMap.get(con3.id).employeeNumber__c != null, 'Employee3 number not created.' ); 
		// Ensure that not Employees are not given a code and number
		System.assert( dbContactMap.get(con4.id).employeeCode__c == null, 'Employee4 code created when not an employee.' ); 
		System.assert( dbContactMap.get(con4.id).employeeNumber__c == null, 'Employee4 number created when not an employee.' ); 

		// Assert that the employee number is incrementing 
		System.assert( dbContactMap.get(con5.id).employeeNumber__c > dbContactMap.get(con3.id).employeeNumber__c, 
						'Employee numbers not incrementing correctly.' ); 

		list<String> employeeCodes = new String[] { dbContactMap.get(con1.id).employeeCode__c, 
													dbContactMap.get(con2.id).employeeCode__c,
													dbContactMap.get(con3.id).employeeCode__c,
													dbContactMap.get(con5.id).employeeCode__c};
		list<c2g__codaDimension4__c> dim4s = [ select name, c2g__ReportingCode__c from c2g__codaDimension4__c where name in :employeeCodes];
		System.Assert( dim4s.size() == 4, 'Dims not created correctly');
		log.debug(dim4s);

	}
	
}