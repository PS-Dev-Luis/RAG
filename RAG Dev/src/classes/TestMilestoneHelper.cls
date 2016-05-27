/**
 *	TestMilestoneHelper
 *	===================
 *	Helper class to check Milestones created as part of the Project Approval  process.
 *
 *	Luis Valenzuela 20/02/2013
 *
 **/
@isTest (seeAllData = true) 
public with sharing class TestMilestoneHelper 
{		
	
	// Methods to check the correct Milestones have been returned
	// Check Milestones for a Project with Billing type not 'Fixed Price'/'Retainer'/'Time and Materials'.
	public static boolean checkStdProjectMS( pse__Proj__c project )
	{
		Map<String, pse__Milestone__c> milestones = getMilestones(project);
		return ( checkDBChargeMS(project, milestones) &&
					checkAdminChargeMS(project, milestones)  &&
						checkSubExpMS( project, milestones) &&
							checkExpMS( project, milestones) &&
								checkPassThroughMS(project, milestones));
	}	
	
	// Check Milestones for a Project of Billing type 'Fixed Price'.
	public static boolean checkFixPriProjectMS( pse__Proj__c project )
	{
		Map<String, pse__Milestone__c> milestones = getMilestones(project);
		return ( checkProfFeeMS(project, milestones) &&
					checkDBChargeMS(project, milestones) &&
						checkAdminChargeMS(project, milestones) &&
							checkSubExpMS( project, milestones) &&
								checkExpMS( project, milestones) &&
									checkPassThroughMS(project, milestones));
	}
	
	// Check Milestones for a Project of Billing type 'Retainer'.
	public static boolean checkRetainProjectMS( pse__Proj__c project )
	{
		Map<String, pse__Milestone__c> milestones = getMilestones(project);
		return ( checkProfFeeMS(project, milestones) &&
					checkDBChargeMS(project, milestones) &&
						checkAdminChargeMS(project, milestones) &&
							checkSubExpMS( project, milestones) &&
								checkExpMS( project, milestones) &&
									checkPassThroughMS(project, milestones));
	}

	// Check Milestones for a Project of Billing type 'Time and Materials'.
	public static boolean checkTandMProjectMS( pse__Proj__c project )
	{
		Map<String, pse__Milestone__c> milestones = getMilestones(project);
		return ( checkDBChargeMS(project, milestones) &&
					checkAdminChargeMS(project, milestones) &&
						checkSubExpMS( project, milestones) &&
							checkSubFeeMS(project, milestones) &&
								checkExpMS( project, milestones) &&
									checkPassThroughMS(project, milestones));
	}

	// Check Milestones for a Project of Billing type 'Time and Materials'.
	public static boolean checkInternalProjectMS( pse__Proj__c project )
	{
		Map<String, pse__Milestone__c> milestones = getMilestones(project); 
		return milestones.isEmpty();
	}
	
	
	// Methods for checking the contents of the returned Milestones	
	private static boolean checkProfFeeMS(pse__Proj__c project, map<String, pse__Milestone__c> milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_PROF_FEE ), 'Milestone not found - ProfFee' );
		return true;
	}
	
	private static boolean checkDBChargeMS(pse__Proj__c project, map<String, pse__Milestone__c> milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_DB_CHARGE ), 'Milestone not found - DB charge.' );
		return true;
	}
	
	private static boolean checkAdminChargeMS(pse__Proj__c project, map<String, pse__Milestone__c> milestones)
	{
		System.assert( milestones.containsKey( RefData.MS_NAME_ADMIN_CHARGE ), 'Milestone not found - Admin charge.' );
		return true;
	}
	
	private static boolean checkSubFeeMS(pse__Proj__c project, map<String, pse__Milestone__c> milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_SUBCONTRACTOR_FEE ), 'Milestone not found - Subcontractor Fee.' );
		return true;
	}
	
	private static boolean checkSubExpMS(pse__Proj__c project, map<String, pse__Milestone__c>milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_SUBCONTRACTOR_EXP ), 'Milestone not found - Subcontractor Exp.' );
		return true;
	}
	
	private static boolean checkPassThroughMS(pse__Proj__c project, map<String, pse__Milestone__c> milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_PASS_THROUGH_COSTS ), 'Milestone not found - Pass through costs.' );
		return true;
	}
	
	private static boolean checkExpMS(pse__Proj__c project, map<String, pse__Milestone__c>milestones)
	{
		System.assert(milestones.containsKey( RefData.MS_NAME_EXPENSES ), 'Milestone not found - Out of Pocket Expenses.' );
		return true;
	}
	
	// Utility Method to retrieve generated milestones for inserted Project
	public static Map<String, pse__Milestone__c> getMilestones(pse__Proj__c project)
	{
		Map<String, pse__Milestone__c> returnMilestones = new Map<String, pse__Milestone__c>();
		List<pse__Milestone__c> milestones = 
			[ Select
					Name, 
					pse__Project__c,  
					pse__Target_Date__c, 
					pse__Actual_Date__c,
					pse__Milestone_Amount__c,
					//Calculated_Database_Charge_Applied__c,
					CurrencyIsoCode,
					pse__Status__c,
					pse__Approved__c,
					pse__Include_In_Financials__c,
					pse__Closed_for_Expense_Entry__c,
					pse__Closed_for_Time_Entry__c			
				from
					pse__Milestone__c
				where
					pse__Project__c = :project.Id ];		

		log.debug(project);
		log.debug('Milestones');
		log.debug(milestones); 
		
		for( pse__Milestone__c mileStone : milestones)
		{
			if( !returnMilestones.containsKey(mileStone.Name) )
			{
				// Remove the project code as this is appended onto admin and db milestone names.
				returnMilestones.put( mileStone.Name.remove( mileStone.Name.substringAfter('-') ) , milestone );
			}
			else
			{
				// Only 1 milestone should exist for each type
				System.assert(false, 'Multiple Milestones of type: ' + mileStone.Name);
			}
		}
		return returnMilestones;
	} // end of getMilestones
	
	
}