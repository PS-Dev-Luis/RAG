public with sharing class OppUnlockingTriggerHandler {

	OpportunitySelector oppSelector = new OpportunitySelector();

	public void validate(List<pse__Proj__c> projectList)
	{
		List<Id> updateList = new List<Id>();
		for(pse__Proj__c proj : projectList)
		{
			if(proj.Unlock_Opportunity__c == true)
			{
				updateList.add(proj.pse__Opportunity__c);
			}
		}
		List<Opportunity> oppList = oppSelector.getLockedOpps(updateList);
		//throw new AppException(oppList + '');
		for(Opportunity opp : oppList)
		{
			opp.Locked__c = false;
		}
		//throw new AppException(oppList + '');
		update oppList;
	}
}