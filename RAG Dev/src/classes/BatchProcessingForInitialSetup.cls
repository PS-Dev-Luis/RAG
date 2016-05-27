global class BatchProcessingForInitialSetup implements Database.Batchable<sObject>, Database.Stateful {
 
    String query;
    global Boolean finished {get; set;}
   
    global BatchProcessingForInitialSetup (String initialQuery) {
        query = initialQuery;
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
 
        if (pse__Region__c.sObjectType == batch.get(0).getsObjectType())
        {
            List<pse__Region__c> regionList = (List<pse__Region__c>)batch;
            for (pse__Region__c obj : regionList) {
                obj.pse__Region_ID_Chain__c = null;
            }
        }
        else if (pse__Practice__c.sObjectType == batch.get(0).getsObjectType())
        {   
            List<pse__Practice__c> practiceList = (List<pse__Practice__c>)batch;
            for (pse__Practice__c obj : practiceList ) {
                obj.pse__Practice_ID_Chain__c = null;
            }  
        }
        else if (pse__Grp__c.sObjectType == batch.get(0).getsObjectType())
        {
            List<pse__Grp__c> grpList = (List<pse__Grp__c>)batch;
            for (pse__Grp__c obj : grpList ) {
                obj.pse__Group_ID_Chain__c = null;
            }
        }
        else if (pse__Proj__c.sObjectType == batch.get(0).getsObjectType()) {
            List<pse__Proj__c> projList = (List<pse__Proj__c>)batch;
            for (pse__Proj__c obj : projList ) {
                obj.pse__Project_ID_Chain__c = null;
            }
        }
       
        try {
            update batch;
        } catch(DMLException e) { }
    }
   
    global void finish(Database.BatchableContext BC) {
    }
 
}