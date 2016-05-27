/**
*	MilestoneCreationHelper
*	======================
*	Helper class that builds appropriate Milestones associated with a
*	Project approval event.
*
*	Luis Valenzuela 21/02/2013
*
*/
public with sharing class MilestoneCreationHelper 
{
	
	private static Map<String, Product2> serviceProducts = new Map<String, Product2>();
	
	public static Map<Id, String> createMilestones( List<pse__Proj__c> projects )
	{
		Map<Id, String> projectErrors = new Map<Id, String>();
	
		List<pse__Milestone__c> insertMilestones = new List<pse__Milestone__c>();
		for(pse__Proj__c proj : projects)
		{
			if(proj.is_internal_project__c)
			{
				// Do not create milestones for internal projects
				continue;
			}
			
			if(proj.pse__Billing_Type__c == RefData.PROJ_BT_FIXED_PRICE || proj.pse__Billing_Type__c == RefData.PROJ_BT_RETAINER )
			{
				insertMilestones.add( createProfFeeMilestone(proj) );
			}
			else if(proj.pse__Billing_Type__c == RefData.PROJ_BT_TIME_AND_MATERIALS )
			{
				insertMilestones.add( createSubFeeMilestone(proj) );		
			}
			// Common Milestones
			insertMilestones.add( createSubExpMilestone(proj) );
			insertMilestones.add( createPassThroughExpMilestone(proj) );
			insertMilestones.add( createDBChargeMilestone(proj) );
			insertMilestones.add( createAdminChargeMilestone(proj) );	
			insertMilestones.add( createExpChargeMilestone(proj) );	
		}

		// Save generated Milestones to the DB
		Database.Saveresult[] dbSrs = Database.insert( insertMilestones , false);
		Log.debug(insertMilestones);
		for(Integer i = 0; i < dbSrs.size(); i++)
		{
			if(!dbSrs[i].isSuccess() )
			{
				Id projectId = insertMilestones[i].pse__Project__r.id;
				String projectName = insertMilestones[i].pse__Project__r.Name;
				String errorMsg = 'Failed to create approval Milestones for project: ' + ProjectName + '\n';
				for( Database.Error err : dbSrs[i].errors )
				{
					errorMsg += '\n' + err.getMessage();
				}
	    		projectErrors.put( ProjectId , errorMsg ) ;
			 	Log.warn(errorMsg); 
			}
		}
		return projectErrors;
	}
	
	// CD0387 [Req 2.4]	
	public static pse__Milestone__c createProfFeeMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_PROF_FEE;
		Product2 prod = getServiceProducts().get( RefData.MS_NAME_PROF_FEE);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		milestone.pse__Target_Date__c = Date.today();  
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = 
			project.get( DynamicFieldRef.PROJ_PROJECT_VALUE_FIELD ) != null ? 
				(decimal) project.get( DynamicFieldRef.PROJ_PROJECT_VALUE_FIELD ) : 0.00;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;	
		return milestone;
	}

	// CD0387 [Req 2.5]	
	public static pse__Milestone__c createDBChargeMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_DB_CHARGE + ' ' +
			(project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) != null ? 
				' ' + project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) : ''); // do not insert null proj code
		Product2 prod = getServiceProducts().get( RefData.PROD_DB_CHARGE);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		milestone.pse__Target_Date__c = Date.today(); 
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = (project.Database_Charge_Applied__c * project.Proposed_Professional_Fee__c) / 100;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;	
		return milestone;
	}

	// CD0387 [Req 2.6]	
	public static pse__Milestone__c createAdminChargeMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_ADMIN_CHARGE + ' ' +
			(project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) != null ? 
				' ' + project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) : ''); // do not insert null proj code		
		Product2 prod = getServiceProducts().get( RefData.PROD_ADMIN_CHARGE);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		milestone.pse__Target_Date__c = Date.today();  
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = (project.Admin_Charge_Applied__c * project.Proposed_Professional_Fee__c) / 100;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;
		return milestone;
	}


	// CD0387 [Req 2.7]
	public static pse__Milestone__c createSubFeeMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_SUBCONTRACTOR_FEE;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		Product2 prod = getServiceProducts().get(RefData.PROD_PROF_FEE_MS_NAME);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Target_Date__c = Date.today();  
		milestone.pse__Actual_Date__c = Date.today();
		milestone.pse__Milestone_Amount__c = 
			project.get(DynamicFieldRef.PROJ_CALC_SUBCONTRACTOR_LABOR_COST_FIELD) != null ? 
				(decimal) project.get(DynamicFieldRef.PROJ_CALC_SUBCONTRACTOR_LABOR_COST_FIELD) : 0.00;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;
		return milestone;
	}

	// CD0387 [Req 2.8]
	public static pse__Milestone__c createSubExpMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_SUBCONTRACTOR_EXP;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		Product2 prod = getServiceProducts().get(RefData.PROD_OUT_OF_POCKET_EXP);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Target_Date__c = Date.today();  
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = 
			project.get(DynamicFieldRef.PROJ_SUBCONTRACTOR_EXP2_FIELD) != null ? 
				(decimal) project.get(DynamicFieldRef.PROJ_SUBCONTRACTOR_EXP2_FIELD) : 0.00 ;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = refData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;
		return milestone;
	}
	
	// CD0387 [Req 2.9]
	public static pse__Milestone__c createPassThroughExpMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_PASS_THROUGH_COSTS;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		Product2 prod = getServiceProducts().get(RefData.PROD_PASS_THROUGH_COSTS);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Target_Date__c = Date.today(); 
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = 
			project.get(DynamicFieldRef.PROJ_PASS_THROUGH_COSTS2_FIELD) != null ? 
				(decimal) project.get(DynamicFieldRef.PROJ_PASS_THROUGH_COSTS2_FIELD) : 0.00 ;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;
		return milestone;
	}
	
	// CD0387 [Req 2.10] Additional Requirement added 20130702 by Josu 	
	public static pse__Milestone__c createExpChargeMilestone( pse__Proj__c project )
	{
		pse__Milestone__c milestone = new pse__Milestone__c();
		milestone.Name = RefData.MS_NAME_EXPENSES + ' ' +
			(project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) != null ? 
				' ' + project.get(DynamicFieldRef.PROJ_PROJECT_CODE_FIELD) : ''); // do not insert null proj code		
		Product2 prod = getServiceProducts().get(RefData.PROD_OUT_OF_POCKET_EXP);
		if( prod != null)  milestone.ffpsai__ServicesProduct__c = prod.id;
		milestone.pse__Project__c = project.id;
		milestone.pse__Project__r = project;
		milestone.pse__Target_Date__c = Date.today();  
		milestone.pse__Actual_Date__c = Date.today(); 
		milestone.pse__Milestone_Amount__c = ( (project.OOPE_Charge_Applied__c != null ? project.OOPE_Charge_Applied__c : 0.0)  
													* project.Proposed_Professional_Fee__c) / 100;
		milestone.CurrencyIsoCode = project.CurrencyIsoCode;
		milestone.pse__Status__c = RefData.GEN_APPROVED;
		milestone.pse__Approved__c = true;
		milestone.pse__Include_In_Financials__c = true;
		milestone.pse__Closed_for_Expense_Entry__c = true;
		milestone.pse__Closed_for_Time_Entry__c = true;
		return milestone;
	}

	// Utility method to bring back the necessary Service products.
	private static Map<String, Product2> getServiceProducts()
	{
		if( serviceProducts == null | serviceProducts.isEmpty() )
		{
			List<String> prodNames = new List<String> { RefData.PROD_PROF_FEE_MS_NAME, 
															RefData.PROD_OUT_OF_POCKET_EXP, 
																RefData.PROD_PASS_THROUGH_COSTS,
																	RefData.PROD_DB_CHARGE,
																		RefData.PROD_ADMIN_CHARGE}; 
			List<Product2> prods = [ Select id, 
											name 
									   from Product2 
									  where name in :prodNames]; 
			for(Product2 prod : prods)
			{
				serviceProducts.put(prod.name, prod);
			}
		}
		return serviceProducts;	
	}	
}