/**
*	TestMilestoneCreationTrigger
*	============================
*	Test class for changes made as part of CD0387 associated with milestone creation as a result of a Project Approval.  
* 	
* 	The Milestones created for each type of project are listed below:  
*   Standard 	- Database Charge, Admin Charge, Subcontractor Expenses, Pass Through Costs
* 	Fixed Price - Professional Fees, Database Charge, Admin Charge, Subcontractor Expenses, Pass Through Costs
* 	Retainer 	- Professional Fees, Database Charge, Admin Charge, Subcontractor Expenses, Pass Through Costs
* 	T&M 		- Database Charge, Admin Charge, Subcontractor Fee, Subcontractor Expenses, Pass Through Costs
*
*	Luis Valenzuela 19/02/2013
*/
@isTest (seeAllData = true)
public with sharing class TestMilestoneCreationTrigger 
{
	
	public static final decimal PROPOSED_INTERNAL_LABOR_COST = 100; 
	public static final decimal SUBCONTRACTOR_LABOUR_COST = 200;
	public static final decimal SUBCONTRACTOR_EXPENSES = 300;
	public static final decimal PASS_THROUGH_COSTS = 400;
	public static final decimal PERCENTAGE_SUBFEE_APPLIED = 0.025;
	public static final decimal PROPOSED_TOTAL_FEE = 800;
	public static final decimal PROPOSED_PROF_FEE = 800;

	/**
	* 	TEST 1 : testStdMilestoneCreation
	*	Test creation of Milestones after insert or update of project 
	* 	===============================================================================================
	*	start conditions 	- 1 standard project set for approval
	*	action 				- Project approved
	*	end state 			- New Milestones created 
	*/	
	@isTest (seeAllData = true)
	public static void testStdMilestoneCreation()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;

		opportunity opp = testHelper.setupOpportunity('Test Opp 1');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
		opp.amount										= PROPOSED_PROF_FEE;
		insert opp;
		
	 	// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test 1 Project' );
		project.pse__Opportunity__c = opp.id;
		project.pse__Is_Active__c = true;
		insert project;
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );	
		// If approval process fails then simulate by setting the flag manually
		if( succesVal == false )
		{
			project.Generate_Milestones__c = true;
			update project;	
		} 
		System.assert( TestMilestoneHelper.checkStdProjectMS(project), 'Standard project failed to create correct milestones.' );

	} // End of Test 1	


	/**
	* 	TEST 2 : testFixedPriceProjMilestoneCreation
	*	Test creation of Milestones after insert or update of project of Billing Type of Fixed Price 
	* 	============================================================================================
	*	start conditions 	- 1 'Fixed Price' project set for approval
	*	action 				- Project approved
	*	end state 			- New Milestones created 
	*/	
	@isTest (seeAllData = true)
	public static void testFixedPriceProjMilestoneCreation()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;

		opportunity opp = testHelper.setupOpportunity('Test Opp 2');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
		opp.amount										= PROPOSED_PROF_FEE;
		insert opp;
		
		// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject('Test 2 Project' );
		project.pse__Billing_Type__c = RefData.PROJ_BT_FIXED_PRICE;
		project.pse__Is_Active__c = true;
		insert project;
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );			
		// If approval process fails then simulate by setting the flag manually
		if( succesVal == false )
		{
			project.Generate_Milestones__c = true;
			update project;	
		} 
		System.assert( TestMilestoneHelper.checkFixPriProjectMS(project), 'Fixed price project failed to create correct milestones.' );
	} // End of Test 2


	/**
	* 	TEST 3 : testRetainerProjMilestoneCreation
	*	Test creation of Milestones after insert or update of project of Billing Type of Retainer 
	* 	============================================================================================
	*	start conditions 	- 1 'Fixed Price' project set for approval
	*	action 				- Project approved
	*	end state 			- New Milestones created 
	*/	
	@isTest (seeAllData = true)
	public static void testRetainerProjMilestoneCreation()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;

	 	opportunity opp = testHelper.setupOpportunity('Test Opp 3');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
		opp.amount										= PROPOSED_PROF_FEE;
		insert opp;
		
		// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject('Test 3 Project' );
		project.pse__Billing_Type__c = RefData.PROJ_BT_RETAINER;
		project.pse__Is_Active__c = true;
		insert project;
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );	
		// If approval process fails then simulate by setting the flag manually
		if( succesVal == false )
		{
			project.Generate_Milestones__c = true;
			update project;	
		} 
		System.assert( TestMilestoneHelper.checkRetainProjectMS(project), 'Retainer project failed to create correct milestones.' );
	
	} // End of Test 3

	
	/**
	* 	TEST 4 : testTimAndMatProjMilestoneCreation
	*	Test creation of Milestones after insert or update of project of Billing Type of Time & Materials 
	* 	=================================================================================================
	*	start conditions 	- 1 'Tim and Materials' project set for approval
	*	action 				- Project approved
	*	end state 			- New Milestones created 
	*/	
	@isTest (seeAllData = true)
	public static void testTimAndMatProjMilestoneCreation()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		opportunity opp = testHelper.setupOpportunity('Test Opp 4');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
		opp.amount										= PROPOSED_PROF_FEE;
		insert opp;
		
		// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test 4 Project' );
		project.pse__Billing_Type__c = RefData.PROJ_BT_TIME_AND_MATERIALS;
		project.pse__Is_Active__c = true;
		insert project;
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );
				// If approval process fails then simulate by setting the flag manually
		if( succesVal == false )
		{
			project.Generate_Milestones__c = true;
			update project;	
		} 
		System.assert( TestMilestoneHelper.checkTandMProjectMS(project), 'T & M project failed to create correct milestones.' );
	
	} // End of Test 4
	
		
 	/**	
	* 	TEST 5 : testInternalProjectMilestoneCreation
	*	Test creation of Milestones after insert or update of project of Billing Type of Time & Materials 
	* 	=================================================================================================
	*	start conditions 	- 1 internal project set for approval
	*	action 				- Project approved
	*	end state 			- No Milestones created 
	*/	
	@isTest (seeAllData = true)
	public static void testInternalProjectMilestoneCreation()
	{
		// Test only in Dev Org
		if( !TestHelper.isDevOrg() ) return;
	
		opportunity opp = testHelper.setupOpportunity('Test Opp 4');
		opp.Proposed_Internal_Labor_Cost__c 			= PROPOSED_INTERNAL_LABOR_COST; 
		opp.Calculated_Internal_Labour_Cost__c			= PROPOSED_INTERNAL_LABOR_COST;
		opp.Subcontractor_Labour_Cost__c 				= SUBCONTRACTOR_LABOUR_COST;
		opp.Subcontractor_Expenses__c 					= SUBCONTRACTOR_EXPENSES;
		opp.Pass_Through_Costs__c 						= PASS_THROUGH_COSTS;
		opp.Percentage_SubFee_Markup__c				 	= PERCENTAGE_SUBFEE_APPLIED; 
		opp.amount										= PROPOSED_PROF_FEE;
		insert opp;
		
		// Create a Project for approval.
	 	pse__Proj__c project = TestHelper.setupProject( 'Test 4 Project' );
		project.pse__Billing_Type__c = RefData.PROJ_BT_TIME_AND_MATERIALS;
		project.pse__Is_Active__c = true;
		project.is_internal_project__c = true;
		insert project;
		// If submit succeeds try and approve else set to false without approval attempt		
		boolean succesVal = ( TestApprovalHelper.submitObjForApproval(project) 
								? TestApprovalHelper.approveObj(project) 
									: false );
		// If approval process fails then simulate by setting the flag manually
		if( succesVal == false )
		{
			project.Generate_Milestones__c = true;
			update project;	
		} 

		System.assert( TestMilestoneHelper.checkInternalProjectMS(project), 'Internal project created milestones.' );
	
	} // End of Test 4	
}