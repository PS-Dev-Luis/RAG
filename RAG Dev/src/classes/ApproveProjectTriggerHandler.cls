public with sharing class ApproveProjectTriggerHandler {

    private OpportunitySelector opSelector = new OpportunitySelector();
    private Map<String, Schema.SObjectField> globalFieldDescribe = Schema.getGlobalDescribe().get('pse__Proj__c').getDescribe().fields.getMap();

    public void validate(List<pse__Proj__c> projects) {

        if(globalFieldDescribe.containsKey('pse__Stage__c'))
        {
            List<Opportunity> oppList;
            List<Id> idList = new List<Id>();
            for(pse__Proj__c p : projects)
            {
                if(p.get('pse__Stage__c')=='Practice Approval')
                {
                    idList.add(p.pse__Opportunity__c);
                }
            }

            oppList = opSelector.getOpps(idList);
            for(Opportunity o : oppList)
            {
                o.Locked__c = true;
            }

            update oppList;

        }
    }
}