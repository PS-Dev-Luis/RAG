public with sharing class OpportunitySelector {

    public List<Opportunity> getOpps(List<Id> idList)
    {
        return Database.query('Select id, Locked__c from Opportunity where Id in :idList and Locked__c = false');
    }

    public List<Opportunity> getLockedOpps(List<Id> idList)
    {
        return Database.query('Select id, Locked__c from Opportunity where Id in :idList and Locked__c = true');
    }    
}