/**
*	RecalculateOpportunityCostsHandler
*	==================================
*	Handler class for the following actions: insert/update/delete/undelete ResourceRequest.
*	Recalculates internal costs for an Opportunity based on the logic provided by the EstimateRevController. 
*
*	Luis Valenzuela 25/02/2013
*
*/
public with sharing class RecalculateOpportunityCostsHandler 
{
	/**
	 * Recalculate as a result of a resource request trigger action
	 **/
	public static void recalculateInternalCosts( List<pse__Resource_Request__c> resReqs)
	{
		map<id, Opportunity> opportunityIds = new map<id, Opportunity>();	
		// List<pse__Resource_Request__c> allResReqs = new List<pse__Resource_Request__c>();
		// Build list of Opportunities referenced by inserted Resource Requests
		for( pse__Resource_Request__c resReq : resReqs )
		{
			opportunityIds.put( resReq.pse__Opportunity__c, resReq.pse__Opportunity__r );
		}	
		recalculateInternalCosts(opportunityIds);
	}								 


	public static void recalculateInternalCosts( map<id, Opportunity> opportunityIds)
	{
		// Retrieve Pojects associated with Opportunities
		List<Opportunity> opps = [  Select 	Id, 
											(Select id,
													pse__Resource_Role__c, 
													pse__Suggested_Bill_Rate_Number__c,
													pse__Suggested_Bill_Rate_Currency_Code__c, 
													pse__Average_Cost_Rate_Number__c, 
													pse__Average_Cost_Rate_Currency_Code__c,
                                            		pse__SOW_Hours__c,
													pse__Opportunity__r.CurrencyIsoCode
											  From	pse__Resource_Requests__r) 
									  From 	Opportunity
									 Where	Id IN :opportunityIds.keyset() ];
									 
		for(Opportunity opp : opps)
		{
			try
			{
				EstimateRevHelper revHlpr = new EstimateRevHelper(opp);
				revHlpr.calculateEstimates( opp.pse__Resource_Requests__r);
				opp.put( DynamicFieldRef.OPP_INT_LABOUR_COST_FIELD, revHlpr.totalEstimatedCost);
				opp.put( DynamicFieldRef.OPP_CALC_INT_LABOUR_COST_FIELD, revHlpr.totalEstimatedRevenue);
			} 
			catch (exception e)
			{
				// If the recalculation has been initiated by an opportunity change
				if( opportunityIds.get(opp.id) != null )
				{
					opportunityIds.get(opp.id).addError('Unable to recalculate internal labout costs : ' + e.getMessage());
				}
				else
				{
					throw new appException( 'Unable to recalculate internal labout costs : ' + e.getMessage() );
				}	
			}	
		}
		try
		{
			update opps;
		}
		catch (exception e)
		{
			// Fail gracefully and don't stop insert of Project.
        	Log.warn( 'Failed to recalculate internal costs on Opportunity.');
		}
	}
}