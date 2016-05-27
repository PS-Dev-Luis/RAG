/**
* EstimateRevHelper
* =================
* This class implements the business logic concerned with building total costs/revenues
* associated with an Opportunity, building an aggragrate by Resource Request role.
*
* 1/3/2013	Luis Valenzuela
*
**/
public with sharing class EstimateRevHelper 
{
    private Opportunity Opp;
    public List<RevenueCostWrapper> revenueCostWrapperList {get; set;}
    public Decimal totalHours {get; set;}
    public Decimal blendedHourlyRateTotal {get;set;}
    public Decimal blendedCostRateTotal {get;set;}
    public Decimal totalEstimatedCost {get; set;}
    public Decimal totalEstimatedRevenue {get;set;}
    
    public EstimateRevHelper( Opportunity inOpp ) 
    {
    	this.opp = inOpp;
        totalHours = 0.00;
        blendedHourlyRateTotal = 0.00;
        blendedCostRateTotal = 0.00;
        totalEstimatedCost = 0.00;
        totalEstimatedRevenue = 0.00;
    }
	
	// When passed an Opportunity, retrieve associated Resource requests and calcluate the Estimates based on them. 
    public void calculateEstimates() 
    {
        List<pse__Resource_Request__c> rRequests  = getResourceReqs(opp);
    	calculateEstimates( rRequests );
    }
    
	// When passed an Opportunity and Associated Resource Requests calculates the Estimates based on them.
	// ResReqs must have the required fields id, pse__Resource_Role__c, pse__Suggested_Bill_Rate_Number__c, 
    // pse__Average_Cost_Rate_Number__c, pse__SOW_Hours__c 
    public void calculateEstimates( List<pse__Resource_Request__c> rRequests ) 
    {
        revenueCostWrapperList = new List<RevenueCostWrapper>();
     	if (rRequests != null && !rRequests.isEmpty()) 
		{
   
			Map<String, Decimal> roleTotalHours = new Map<String, Decimal>();
			Map<String, Decimal> estRevenueMap = new Map<String, Decimal>();
			Map<String, Decimal> estCostMap = new Map<String, Decimal>();
			decimal tempVar = 0.0;
			decimal estRev = 0.0;
			decimal estCost = 0.0;
			decimal total  = 0.0;
			
			// Build Total hours, total estimated Revenue and total estimated cost per Resource Role
	        for(pse__Resource_Request__c rr : rRequests) 
	        {
				/* Aggregate Estimated Revenue */
	            estRev = ( estRevenueMap.containsKey(rr.pse__Resource_Role__c ) ? estRevenueMap.get(rr.pse__Resource_Role__c) : 0.0); 
	            // Convert to Opp currency
                if (rr.pse__Suggested_Bill_Rate_Number__c != null)
                {
                	tempVar = CurrencyHelper.convertFromTo( rr.pse__Suggested_Bill_Rate_Number__c * rr.pse__SOW_Hours__c,
                 												rr.pse__Suggested_Bill_Rate_Currency_Code__c, 
                 													rr.pse__Opportunity__r.CurrencyIsoCode );
                }
                else
                {
                	tempVar = 0.00;
                }
                estRevenueMap.put(rr.pse__Resource_Role__c, estRev  + tempVar);
	             
	             
	            /* Aggregate Estimated Cost */
	            estCost = ( estCostMap.containsKey(rr.pse__Resource_Role__c ) ? estCostMap.get(rr.pse__Resource_Role__c) : 0.0); 
	            // Convert to Opp currency
                if (rr.pse__Average_Cost_Rate_Number__c != null)
                {
                	tempVar = CurrencyHelper.convertFromTo( rr.pse__Average_Cost_Rate_Number__c * rr.pse__SOW_Hours__c,
                 												rr.pse__Average_Cost_Rate_Currency_Code__c, 
                 													rr.pse__Opportunity__r.CurrencyIsoCode );
                }
                else
                {
                	tempVar = 0.00;
                }
                estCostMap.put(rr.pse__Resource_Role__c, estCost  + tempVar);
	            
	            
	         
	            /* Total Hours */
				total = ( roleTotalHours.containsKey(rr.pse__Resource_Role__c) ? roleTotalHours.get(rr.pse__Resource_Role__c) : 0.00);
	            roleTotalHours.put(rr.pse__Resource_Role__c, total + rr.pse__SOW_Hours__c);
	            
	        } // end of for loop
	    
	    	// Build up totals and create RevenueCostWrapper List
	        for(String role : roleTotalHours.keySet()) 
	        {
	            totalHours += roleTotalHours.get(role).setScale(2);
	            totalEstimatedRevenue += estRevenueMap.get(role).setScale(2);
	            totalEstimatedCost += estCostMap.get(role).setScale(2); 
	            revenueCostWrapperList.add(new RevenueCostWrapper(role, estRevenueMap.get(role), estCostMap.get(role), roleTotalHours.get(role) ));
	        }
	        
	        blendedHourlyRateTotal = (totalEstimatedRevenue / totalHours).setScale(2);
	        blendedCostRateTotal = (totalEstimatedCost / totalHours).setScale(2) ;
	    }
	    return;
    } // end of calculateEstimate

	
	// Utility method to return Required ResReq fields for opp 
    private List<pse__Resource_Request__c> getResourceReqs(Opportunity opp ) 
    {
    	List<pse__Resource_Request__c> rRequests = [ Select id,
        													pse__Resource_Role__c, 
        													pse__Suggested_Bill_Rate_Number__c,
        													pse__Suggested_Bill_Rate_Currency_Code__c, 
        													pse__Average_Cost_Rate_Number__c, 
        													pse__Average_Cost_Rate_Currency_Code__c,
                                                    		pse__SOW_Hours__c,
															pse__Opportunity__r.CurrencyIsoCode
                                                       from pse__Resource_Request__c 
                                                 	  where Pse__Opportunity__c = :Opp.Id];
    	return rRequests;
    }// end of get ResourceReqs                  	                                  	              	
}