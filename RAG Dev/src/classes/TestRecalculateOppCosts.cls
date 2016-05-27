/**
*	TestRecalculateOppCosts
*	=======================
*	Test class for changes made as part of CD0387 associated with triggers on Resource Request objects.
*  	The functionality being tested is around the two custom fields on the Opportunity object
* 	Proposed_Internal_Labor_Cost__c Calculated_Internal_Labour_Cost__c 
*	The calculation of aggregate values from Resource Request is based on Logic provided by the
*	EstimateRevController.		
*
*	Luis Valenzuela 28/02/2013
*
*/
@isTest (seeAllData = true)
private class TestRecalculateOppCosts 
{

	private static String OPP_QUERY = 
		'Select Id, Proposed_Internal_Labor_Cost__c, Calculated_Internal_Labour_Cost__c From Opportunity where Id ';
	
	/**
	* 	TEST 1 : testRecalcAfterInsert
	*	Test recalculation after insert of Resource Request
	* 	==================================================================
	*	start conditions 	- 1 opportunity exists
	*	action 				- insert of Resource Requests onto opportunity
	*	end state 			- opp's internal fields recalculated to the correct value
	*/	
	@isTest (seeAllData = true)
	public static void testRecalcAfterInsert()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		// Populate & insert Opportunity			
		opportunity opp = testHelper.setupOpportunity('Test Opp 1');
		insert opp;
		
		// Populate Resource Requests
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		resReq1.pse__Suggested_Bill_Rate_Number__c = 10; 
		resReq1.pse__Average_Cost_Rate_Number__c = 5; 
		resReq1.pse__SOW_Hours__c = 10;
		resReq1.pse__Opportunity__c = opp.Id;

		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq2.pse__Suggested_Bill_Rate_Number__c = 20; 
		resReq2.pse__Average_Cost_Rate_Number__c = 15; 
		resReq2.pse__SOW_Hours__c = 20;
		resReq2.pse__Opportunity__c = opp.Id;
	
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2};
		insert resReqs;
		
        Id oppId = opp.id;
		String query = OPP_QUERY + ' =  :oppId';
		Opportunity updOpp = Database.query(query);
		 												
		// ASSERT that the Opp totals are correct
		decimal result = ( resReq1.pse__Average_Cost_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Average_Cost_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) updOpp.get(DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD) == result , 
				'TestTrigger TEST 1 Failed : Proposed_Internal_Labor_Cost__c value incorrect.');
		
		// (10 * 10) + (10 * 20) = 300		
		result = ( resReq1.pse__Suggested_Bill_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Suggested_Bill_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) updOpp.get(DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD) == result ,  
				'TestTrigger TEST 1 Failed : Calculated_Internal_Labour_Cost__c value incorrect.');				
	} //  end of TEST1


	/**
	* 	TEST 2 : testRecalcAfterUpdate
	*	Test recalculation after update of trigger fields on Resource Request
	* 	=====================================================================
	*	start conditions 	- 1 opportunity exists with Res Reqs Attached
	*	action 				- update of trigger field on resReq
	*	end state 			- opp's internal fields recalculated to the correct value
	*/	
	@isTest (seeAllData = true)
	public static void testRecalcAfterUpdate()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		// Populate & insert Opportunity			
		Opportunity opp1 = testHelper.setupOpportunity('Test Opp 1');
		Opportunity opp2 = testHelper.setupOpportunity('Test Opp 1');
		Opportunity opp3 = testHelper.setupOpportunity('Test Opp 1');

		// Insert Opportunities
		Opportunity[] opps = new Opportunity[]{opp1, opp2, opp3};
		insert opps;
		
		Set<Id> oppIds = new Set<Id>();
		for( Opportunity opp : opps)
		{
			oppIds.add(opp.Id);
		}
		
		// Populate Resource Request for each opportunity
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		resReq1.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq1.pse__Average_Cost_Rate_Number__c = 1; 
		resReq1.pse__SOW_Hours__c = 1;
		resReq1.pse__Opportunity__c = opp1.Id;

		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq2.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq2.pse__Average_Cost_Rate_Number__c = 1; 
		resReq2.pse__SOW_Hours__c = 1;
		resReq2.pse__Opportunity__c = opp2.Id;

		pse__Resource_Request__c resReq3 = testHelper.setupResourceRequest();
		resReq3.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq3.pse__Average_Cost_Rate_Number__c = 1; 
		resReq3.pse__SOW_Hours__c = 1;
		resReq3.pse__Opportunity__c = opp3.Id;
	
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2, resReq3};
		insert resReqs;
		
		// Update pse__Suggested_Bill_Rate_Number__c	
		resReq1.pse__Suggested_Bill_Rate_Number__c = 10;
		// update pse__Average_Cost_Rate_Number__c
		resReq2.pse__Average_Cost_Rate_Number__c = 10; 
		// update pse__SOW_Hours__c
		resReq3.pse__SOW_Hours__c = 10; 
		update resReqs;
	

		String query = OPP_QUERY + ' IN :oppIds ';
		List<Opportunity> updOpps = Database.query( query );
		
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
		for (Opportunity dbOpp : updOpps)
		{
			oppMap.put(dbOpp.Id, dbOpp);
		} 
	
		decimal result = 0.0;
		Opportunity testOpp; 
		for (pse__Resource_Request__c resReq : resReqs)
		{
			// ASSERT that the Opp totals are correct
			result = ( resReq.pse__Average_Cost_Rate_Number__c * resReq.pse__SOW_Hours__c);		
			testOpp = oppMap.get(resReq.pse__opportunity__c);
			System.Assert( (decimal) testOpp.get(DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD) == result , 
					'TestTrigger TEST 2 Failed : Proposed_Internal_Labor_Cost__c value incorrect.');
			result = ( resReq.pse__Suggested_Bill_Rate_Number__c * resReq.pse__SOW_Hours__c);
			System.Assert( (decimal) testOpp.get(DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD) == result ,  
					'TestTrigger TEST 2 Failed : Calculated_Internal_Labour_Cost__c value incorrect.');				
		}
	} //  end of TEST2
	
	
	/**
	* 	TEST 3 : testRecalcAfterOppMove
	*	Test recalculation after Resource Request moves from 1 Opp to another
	* 	==================================================================
	*	start conditions 	- 1 opportunity exists with Res Reqs Attached
	*	action 				- update of trigger field on resReq
	*	end state 			- opp's internal fields recalculated to the correct value
	*/	
	@isTest (seeAllData = true)
	public static void testRecalcAfterOppMove()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		// Populate & insert Opportunity			
		Opportunity opp1 = testHelper.setupOpportunity('Test Opp 1');
		Opportunity opp2 = testHelper.setupOpportunity('Test Opp 1');
	
		// Insert Opportunities
		Opportunity[] opps = new Opportunity[]{opp1, opp2 };
		insert opps;
		
		Set<Id> oppIds = new Set<Id>();
		for( Opportunity opp : opps)
		{
			oppIds.add(opp.Id);
		}
		
		// Populate Resource Request for each opportunity
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		resReq1.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq1.pse__Average_Cost_Rate_Number__c = 1; 
		resReq1.pse__SOW_Hours__c = 1;
		resReq1.pse__Opportunity__c = opp1.Id;

		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq2.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq2.pse__Average_Cost_Rate_Number__c = 1; 
		resReq2.pse__SOW_Hours__c = 1;
		resReq2.pse__Opportunity__c = opp1.Id;
	
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2};
		insert resReqs;
		
		// Move to a different Opportunity	
		resReq1.pse__Opportunity__c = opp2.id;
		resReq2.pse__Opportunity__c = opp2.id;
		update resReqs;
	
		String query = OPP_QUERY + ' IN  :oppIds';
        List<Opportunity> updOpps = Database.query( query );
		
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
		for (Opportunity dbOpp : updOpps)
		{
			oppMap.put(dbOpp.Id, dbOpp);
		} 
	
	
		// ASSERT that the Opp1 totals are correct, vlaues should be 0.0 as not resReqs exist
		Opportunity testOpp1 = oppMap.get(opp1.id);
		decimal result = 0.0;
		System.Assert( (decimal) testOpp1.get(DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD) == result , 
				'TestTrigger TEST 3 Failed : Proposed_Internal_Labor_Cost__c value incorrect.');
		System.Assert( (decimal) testOpp1.get(DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD) == result ,  
				'TestTrigger TEST 3 Failed : Calculated_Internal_Labour_Cost__c value incorrect.');				

		// ASSERT that the Opp2 totals are correct
		Opportunity testOpp2 = oppMap.get(resReq1.pse__opportunity__c);
		result = ( resReq1.pse__Average_Cost_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Average_Cost_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) testOpp2.get(DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD) == result , 
				'TestTrigger TEST 3 Failed : Proposed_Internal_Labor_Cost__c value incorrect.');
		result = ( resReq1.pse__Suggested_Bill_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Suggested_Bill_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) testOpp2.get(DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD) == result ,  
				'TestTrigger TEST 3 Failed : Calculated_Internal_Labour_Cost__c value incorrect.');				
	} //  end of TEST3
	
	
	/**
	* 	TEST 4 : testRecalcAfterDelete
	*	Test recalculation after delete of Resource Request from Opportunity
	* 	=====================================================================
	*	start conditions 	- 1 opportunity exists with Res Reqs Attached
	*	action 				- delete of resReq
	*	end state 			- opp's internal fields recalculated to the correct value
	*/	
	@isTest (seeAllData = true)
	public static void testRecalcAfterDelete()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		// Populate & insert Opportunity			
		Opportunity opp = testHelper.setupOpportunity('Test Opp 1');
		insert opp;
				
		// Populate Resource Request for each opportunity
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		resReq1.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq1.pse__Average_Cost_Rate_Number__c = 1; 
		resReq1.pse__SOW_Hours__c = 1;
		resReq1.pse__Opportunity__c = opp.Id;

		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		resReq2.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq2.pse__Average_Cost_Rate_Number__c = 1; 
		resReq2.pse__SOW_Hours__c = 1;
		resReq2.pse__Opportunity__c = opp.Id;

		pse__Resource_Request__c resReq3 = testHelper.setupResourceRequest();
		resReq3.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq3.pse__Average_Cost_Rate_Number__c = 1; 
		resReq3.pse__SOW_Hours__c = 1;
		resReq3.pse__Opportunity__c = opp.Id;
		
		pse__Resource_Request__c resReq4 = testHelper.setupResourceRequest();
		resReq4.pse__Suggested_Bill_Rate_Number__c = 1; 
		resReq4.pse__Average_Cost_Rate_Number__c = 1; 
		resReq4.pse__SOW_Hours__c = 1;
		resReq4 .pse__Opportunity__c = opp.Id;	
		
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2, resReq3, resReq4};
		insert resReqs;
		delete resReq3;
		delete resReq4;
	
        
        Id OppId = opp.Id;
        String query = OPP_QUERY + ' = :oppId';
		Opportunity updOpp =  Database.query( query );
			
		// ASSERT that the Opp totals are correct
		decimal result = ( resReq1.pse__Average_Cost_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Average_Cost_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) updOpp.get(DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD) == result , 
				'TestTrigger TEST 4 Failed : Proposed_Internal_Labor_Cost__c value incorrect.');
		result = ( resReq1.pse__Suggested_Bill_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
							( resReq2.pse__Suggested_Bill_Rate_Number__c * resReq2.pse__SOW_Hours__c);
		System.Assert( (decimal) updOpp.get(DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD) == result ,  
				'TestTrigger TEST 4 Failed : Calculated_Internal_Labour_Cost__c value incorrect.');	
	} //  end of TEST4	
}