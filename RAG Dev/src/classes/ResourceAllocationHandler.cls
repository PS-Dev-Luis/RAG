/**
*	ResourceAllocationHandler
*	=========================
*	Handler class for the following actions: insert Project, insert Resource Request.
*	Associates correct Projects to Resource Requests from Opportunities.
*
*	Luis Valenzuela 19/02/2013
*
*/
public with sharing class ResourceAllocationHandler 
{
	/**
	 *	Upon creation of a new Project on an Opportunity, all associated resource requests 
	 * 	on the Opportunity shall be automatically associated with the new Project.
	 **/
	public static void handleProjectInsert( List<pse__Proj__c> projects )
	{
		Set<Id> opportunityIds = new Set<Id>();
		List<pse__Resource_Request__c> updatedResReqs = new List<pse__Resource_Request__c>();
		Map<Id,pse__Proj__c> opportunityProjectMap = new Map<Id,pse__Proj__c>();
		
		// Build list of Opportunities referenced by inserted Projects
		for( pse__Proj__c project : projects )
		{
			opportunityIds.add(project.pse__Opportunity__c);
			opportunityProjectMap.put(project.pse__Opportunity__c , project);
		}	
		// Retrieve Resource Requests associated with Opps
		List<Opportunity> opportunities = [  Select Id, 
													(Select Id, pse__Project__c From pse__Resource_Requests__r) 
											   From Opportunity
											  Where Id IN :opportunityIds ];

		// Build list of Resource Requests to be updated						
		for( Opportunity opp : opportunities )
		{
			for( pse__Resource_Request__c request : opp.pse__Resource_Requests__r )
			{
				request.pse__Project__c = opportunityProjectMap.get(opp.Id).Id;
				updatedResReqs.add(request);
			}
		}	
		 
		try 
		{
            update updatedResReqs;
        } 
        catch(DMLException e) 
        { 
        	// Fail gracefully and don't stop insert of Project.
        	Log.warn( 'Failed to update Resource Requests after Project insert : \n' + e.getMessage());
	    }
	} // end of handleProjectInsert
	
	
	/**
	 *	Upon creation of a new ResourceRequest on an Opportunity, if the Opportunity has a Project 
	 * 	associated with it and the resource request has not been given attached to a project then
	 *  the ResourceRequest shall be automatically associated with that Opportunity's Project.
	 * 	The client has been informed that they must uphold a 1:1 relation between the Opportunity
	 * 	and the Project as this is noit enforced.
	 **/
	public static void handleResourceRequestInsert( List<pse__Resource_Request__c> resReqs )
	{
		
		Set<Id> opportunityIds = new Set<Id>();	
		Map<Id,pse__Proj__c> opportunityProjectMap = new Map<Id,pse__Proj__c>();
		set<Id> multipleProjIds = new Set<Id>();		
	
	
		// Build list of Opportunities referenced by inserted Resource Requests
		for( pse__Resource_Request__c resReq : resReqs )
		{
			opportunityIds.add(resReq.pse__Opportunity__c);
		}	
		// Retrieve Pojects associated with Opportunities
		List<pse__Proj__c> projects = [  Select Id, 
												pse__Opportunity__c
										  From  pse__Proj__c
										 Where pse__Opportunity__c IN :opportunityIds];
		// Exit if no Projects exist
		if( !projects.isEmpty() )		
		{
			Id tempOppId;
			// Build mappings of 1:1 Opp to Proj and ommit duplicates 
			// Business rule that only 1 project can exist on an opportunity, so remove otherwise.
			for( pse__Proj__c proj : projects )
			{
				tempOppId = proj.pse__Opportunity__c;
				if( !opportunityProjectMap.containsKey(tempOppId) && !multipleProjIds.contains(tempOppId) )
				{
					opportunityProjectMap.put( proj.pse__Opportunity__c, proj );
				} 
				else
				{
					// remove opps with multiple projects
					multipleProjIds.add( tempOppId );
					opportunityProjectMap.remove( tempOppId );
				}
			}
				
			pse__Proj__c proj;	
			for( pse__Resource_Request__c resReq : resReqs )
			{
				// Do not overwrite project if already set
				if( null == resReq.pse__Project__c )
				{
					proj = opportunityProjectMap.get(resReq.pse__Opportunity__c);
					if( null != proj)
					{
						resReq.pse__Project__c = proj.Id;
					}		
				}  
			}
		}
		
	} // End of handleResourceRequestInsert		

}