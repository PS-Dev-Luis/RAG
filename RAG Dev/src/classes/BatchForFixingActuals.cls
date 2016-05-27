global class BatchForFixingActuals implements Database.Batchable<sObject> {
 
    String query;
   
    global BatchForFixingActuals (String initialQuery) {
        query = initialQuery;
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
 
        if (pse__Resource_Actuals__c.sObjectType == batch.get(0).getsObjectType())
        {
            List<pse__Resource_Actuals__c> resActuals = (List<pse__Resource_Actuals__c>)batch;
            for (pse__Resource_Actuals__c actual : resActuals) {
                actual.pse__Unique_Name__c = String.valueOf(actual.pse__Resource__c) + '-' + String.valueOf(actual.pse__Time_Period__c) ;
            }
        }
        else if (pse__Project_Actuals__c.sObjectType == batch.get(0).getsObjectType())
        {   
            List<pse__Project_Actuals__c> prjctActuals = (List<pse__Project_Actuals__c>)batch;
            for (pse__Project_Actuals__c actual : prjctActuals ) {
                actual.pse__Unique_Name__c = String.valueOf(actual.pse__Project__c) + '-' + String.valueOf(actual.pse__Time_Period__c) ;
            }  
        }
        else if (pse__Regional_Actuals__c.sObjectType == batch.get(0).getsObjectType())
        {
            List<pse__Regional_Actuals__c> regionActuals = (List<pse__Regional_Actuals__c>)batch;
            for (pse__Regional_Actuals__c actual : regionActuals ) {
                actual.pse__Unique_Name__c = String.valueOf(actual.pse__Region__c) + '-' + String.valueOf(actual.pse__Time_Period__c) ;
            }
        }
        else if (pse__Practice_Actuals__c.sObjectType == batch.get(0).getsObjectType()) {
            List<pse__Practice_Actuals__c> practiceActuals = (List<pse__Practice_Actuals__c>)batch;
            for (pse__Practice_Actuals__c actual : practiceActuals ) {
                actual.pse__Unique_Name__c = String.valueOf(actual.pse__Practice__c) + '-' + String.valueOf(actual.pse__Time_Period__c) ;
            }
        }
        else if (pse__Group_Actuals__c.sObjectType == batch.get(0).getsObjectType()) {
            List<pse__Group_Actuals__c> groupActuals = (List<pse__Group_Actuals__c>)batch;
            for (pse__Group_Actuals__c actual : groupActuals ) {
                actual.pse__Unique_Name__c = String.valueOf(actual.pse__Group__c) + '-' + String.valueOf(actual.pse__Time_Period__c) ;
            }
        }
       
        try {
            update batch;
        } catch(DMLException e) { }
    }
   
    global void finish(Database.BatchableContext BC) {
    }
 
}