/**
*	EstimateRevController
*	=====================
*	Controller class to  generate estimated costs associated with Opportunities.  Used by
* 	EstimateRev VF page.  The calculation logic has been taken out and encapsulated in 
* 	EstimateRevHelper so that it can also be used by the ResourceRequest Trigger to generate
*	estimates which are store on the Opportunity.
*
*	Updated by Luis Valenzuela 25/02/2013
*
*/
public with sharing class EstimateRevController 
{
    private Opportunity Opp;
    public List<RevenueCostWrapper> revenueCostWrapperList {get; set;}
    public Decimal totalHours {get; set;}
    public Decimal blendedHourlyRateTotal {get;set;}
    public Decimal blendedCostRateTotal {get;set;}
    public Decimal totalEstimatedCost {get; set;}
    public Decimal totalEstimatedRevenue {get;set;}
    
    public EstimateRevController(ApexPages.StandardController controller) 
    {
        this.Opp = (Opportunity)controller.getRecord();
     	EstimateRevHelper revHlpr = new EstimateRevHelper(this.Opp);
        revHlpr.calculateEstimates();
        // Set the values from the updated helper
        totalHours = revHlpr.totalHours;
        blendedHourlyRateTotal = revHlpr.blendedHourlyRateTotal;
        blendedCostRateTotal = revHlpr.blendedCostRateTotal;
        totalEstimatedCost = revHlpr.totalEstimatedCost;
        totalEstimatedRevenue = revHlpr.totalEstimatedRevenue;
        revenueCostWrapperList   = revHlpr.revenueCostWrapperList;
    	
    	if (revenueCostWrapperList.isEmpty()) 
		{
		    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Plan Unavailable - No Resource Requests are attached to this Opportunity.'));
	    }
    }    
}