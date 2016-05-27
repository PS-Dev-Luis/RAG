/**
*	TestEstimateRevVFPage
*	============================
*	Test class for EstimateRev VF page and EstimateRevController  
*
*	Luis Valenzuela 26/02/2013
*/
@isTest (seeAllData = true) 
private class TestEstimateRevVFPage 
{

	@isTest (seeAllData = true) 
	public static void testEstimateRevPage()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
		
	 	/* ++++++++++++++++ SETUP ++++++++++++++++++++++++++++ */
		// Populate & insert Opportunity			
		opportunity opp = testHelper.setupOpportunity('Test Opp 1');
		insert opp;
		
    	// Populate Resource Requests
		pse__Resource_Request__c resReq1 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq2 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq3 = testHelper.setupResourceRequest();
		pse__Resource_Request__c resReq4 = testHelper.setupResourceRequest();
		// Resource1
		resreq1.pse__Resource_Role__c = 'Architect';
		resReq1.pse__Suggested_Bill_Rate_Number__c = 30;
		resReq1.pse__Average_Cost_Rate_Number__c = 20;
		resReq1.pse__SOW_Hours__c = 100;
		resReq1.pse__Opportunity__c = opp.Id;
		// Resource2
		resreq2.pse__Resource_Role__c = 'Architect';
		resReq2.pse__Suggested_Bill_Rate_Number__c = 30;
		resReq2.pse__Average_Cost_Rate_Number__c = 20;
		resReq2.pse__SOW_Hours__c = 100;
		resReq2.pse__Opportunity__c = opp.Id;
		// Resource3
		resreq3.pse__Resource_Role__c = 'Consultant';
		resReq3.pse__Suggested_Bill_Rate_Number__c = 50;
		resReq3.pse__Average_Cost_Rate_Number__c = 40;
		resReq3.pse__SOW_Hours__c = 10;
		resReq3.pse__Opportunity__c = opp.Id;
		// Resource4
		resreq4.pse__Resource_Role__c = 'Trainer';
		resReq4.pse__Suggested_Bill_Rate_Number__c = 30;
		resReq4.pse__Average_Cost_Rate_Number__c = 20;
		resReq4.pse__SOW_Hours__c = 50;
		resReq4.pse__Opportunity__c = opp.Id;
		
		// Insert resource requests
		pse__Resource_Request__c[] resReqs = new pse__Resource_Request__c[]{resReq1, resReq2, resReq3, resReq4};
		Database.SaveResult[] lsr = Database.insert( resReqs , false);
		for (Database.SaveResult sr:lsr)
		{
    		if(!sr.isSuccess())
			{
				System.Assert(false, 'Insertion of Resource Requests failed.');
			}
		}

	 	/* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
		// Instantiate VF page  and Controller to check for errors
		PageReference pageRef = Page.EstimateRev;
		Test.setCurrentPage(pageRef);
    	ApexPages.StandardController sc = new ApexPages.standardController(opp);
    	EstimateRevController estRevCtrl = new EstimateRevController(sc);
		// estRevCtrl.calculateEstimate(); Implicitly called by the page load

	 	/* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
		System.Assert( estRevCtrl.totalEstimatedCost == 
			(( resReq1.pse__Average_Cost_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
				( resReq2.pse__Average_Cost_Rate_Number__c * resReq2.pse__SOW_Hours__c) +
					( resReq3.pse__Average_Cost_Rate_Number__c * resReq3.pse__SOW_Hours__c) +
						( resReq4.pse__Average_Cost_Rate_Number__c * resReq4.pse__SOW_Hours__c)).setScale(2)  );
		System.Assert( estRevCtrl.totalEstimatedRevenue == 
			(( resReq1.pse__Suggested_Bill_Rate_Number__c * resReq1.pse__SOW_Hours__c) +
				( resReq2.pse__Suggested_Bill_Rate_Number__c * resReq2.pse__SOW_Hours__c) +
					( resReq3.pse__Suggested_Bill_Rate_Number__c * resReq3.pse__SOW_Hours__c) +
						( resReq4.pse__Suggested_Bill_Rate_Number__c * resReq4.pse__SOW_Hours__c)).setScale(2) );
		System.Assert( estRevCtrl.totalHours == 
			( resReq1.pse__SOW_Hours__c + resReq2.pse__SOW_Hours__c + resReq3.pse__SOW_Hours__c + resReq4.pse__SOW_Hours__c).setScale(2) );
	    System.Assert( estRevCtrl.blendedHourlyRateTotal == (estRevCtrl.totalEstimatedRevenue / estRevCtrl.totalHours).setScale(2) );
	    System.Assert( estRevCtrl.blendedCostRateTotal == (estRevCtrl.totalEstimatedCost / estRevCtrl.totalHours).setScale(2) );		

		String role = null;
		Decimal costPerRole = 0.0; 
		Decimal calcCostPerRole = 0.0;
		Decimal revenuePerRole = 0.0;
		Decimal calcRevPerRole = 0.0;
    	Decimal hourlyRate= 0.0;
		Decimal costRate = 0.0;
		Decimal totalHoursPerRole = 0.0;

		// Assert values per role are as expected.
		for ( Integer i = 0 ; i < estRevCtrl.revenueCostWrapperList.size(); i++)
		{
			role = estRevCtrl.revenueCostWrapperList[i].role;	
			costPerRole = estRevCtrl.revenueCostWrapperList[i].costPerRole; 
			revenuePerRole = estRevCtrl.revenueCostWrapperList[i].revenuePerRole;
	    	hourlyRate= estRevCtrl.revenueCostWrapperList[i].hourlyRate;
			costRate = estRevCtrl.revenueCostWrapperList[i].costRate;
			totalHoursPerRole = estRevCtrl.revenueCostWrapperList[i].totalHoursPerRole;			
		
			// Tests Architects (2)
			if( estRevCtrl.revenueCostWrapperList[i].role == resReq1.pse__Resource_Role__c)
			{
				System.Assert( hourlyRate == resReq1.pse__Suggested_Bill_Rate_Number__c );
        		System.Assert( costRate == resReq1.pse__Average_Cost_Rate_Number__c );
        		System.Assert( totalHoursPerRole == resReq1.pse__SOW_Hours__c + resReq2.pse__SOW_Hours__c );
        		
        		calcCostPerRole = (resReq1.pse__Average_Cost_Rate_Number__c * resReq1.pse__SOW_Hours__c) + 
        							( resReq2.pse__Average_Cost_Rate_Number__c * resReq2.pse__SOW_Hours__c) ;
				System.Assert( costPerRole == calcCostPerRole.setScale(2) );
        		
        		calcRevPerRole = (resReq1.pse__Suggested_Bill_Rate_Number__c * resReq1.pse__SOW_Hours__c) + 
        							(resReq2.pse__Suggested_Bill_Rate_Number__c * resReq2.pse__SOW_Hours__c);
        		System.Assert( revenuePerRole ==  calcRevPerRole.setScale(2)  );
			}
			// Tests for Consultant
			else if( role == resReq3.pse__Resource_Role__c)
			{
				System.Assert( hourlyRate == resReq3.pse__Suggested_Bill_Rate_Number__c );
        		System.Assert( costRate == resReq3.pse__Average_Cost_Rate_Number__c );
        		System.Assert( totalHoursPerRole == resReq3.pse__SOW_Hours__c );
        		
        		calcCostPerRole = resReq3.pse__Average_Cost_Rate_Number__c * resReq3.pse__SOW_Hours__c ;
        		System.Assert( costPerRole == calcCostPerRole.setScale(2)  );
        		
        		calcRevPerRole = resReq3.pse__Suggested_Bill_Rate_Number__c * resReq3.pse__SOW_Hours__c;
        		System.Assert( revenuePerRole ==  calcRevPerRole.setScale(2) );
			} 
			// Tests for Trainer
			else if( role == resReq4.pse__Resource_Role__c)
			{
				System.Assert( hourlyRate == resReq4.pse__Suggested_Bill_Rate_Number__c );
        		System.Assert( costRate == resReq4.pse__Average_Cost_Rate_Number__c );
        		System.Assert( totalHoursPerRole == resReq4.pse__SOW_Hours__c );
        		
        		calcCostPerRole = resReq4.pse__Average_Cost_Rate_Number__c * resReq4.pse__SOW_Hours__c ;
        		System.Assert( costPerRole == calcCostPerRole.setScale(2)  );
        		
        		calcRevPerRole = resReq4.pse__Suggested_Bill_Rate_Number__c * resReq4.pse__SOW_Hours__c;
        		System.Assert( revenuePerRole ==  calcRevPerRole.setScale(2)  );
			}
		} 
		
	} //  end of testEstimateRevPage
    
}