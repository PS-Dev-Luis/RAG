public class InitialSetupWorkForCloningController {
   
    private String query1, query2, query3, query4;
    private String query5, query6, query7, query8, query9;
    private Id batchprocessid1, batchprocessid2, batchprocessid3, batchprocessid4;
    private Id batchIdForActual1, batchIdForActual2, batchIdForActual3, batchIdForActual4, batchIdForActual5;
    public Integer noOfProj { get; set; }
    public Integer noOfPractice { get; set; }
    public Integer noOfRegion { get; set; }
    public Integer noOfGroup { get; set; }
    public Integer noOfResActuals { get; set; }
    public Integer noOfProjActuals { get; set; }
    public Integer noOfRgnActuals { get; set; }
    public Integer noOfPracActuals {get; set; }
    public Integer noOfGrpActuals { get; set; }
    public boolean displayActualBlock { get; set; }
    public boolean disablePrjFixing {get; set;}
    public boolean disableActualFixing {get; set;}
    public boolean batchCompletionStatus {get; set;}
    public boolean batchCompletionStatusForActuals  {get; set;}
    BatchProcessingForInitialSetup batchObject1, batchObject2, batchObject3, batchObject4;
    Set<Id> batchProcessIds;
    Set<Id> batchProcessIdsOfActuals;
   
    public InitialSetupWorkForCloningController () {
        noOfProj = Database.countQuery('select count() from pse__Proj__c');
        noOfRegion = Database.countQuery('select count() from pse__Region__c');
        noOfPractice = Database.countQuery('select count() from pse__Practice__c');
        noOfGroup = Database.countQuery('select count() from pse__Grp__c');
        noOfResActuals = Database.countQuery('select count() from pse__Resource_Actuals__c');
        noOfProjActuals = Database.countQuery('select count() from pse__Project_Actuals__c');
        noOfRgnActuals  = Database.countQuery('select count() from pse__Regional_Actuals__c');
        noOfPracActuals  = Database.countQuery('select count() from pse__Practice_Actuals__c');
        noOfGrpActuals = Database.countQuery('select count() from pse__Group_Actuals__c');
        displayActualBlock = false;
        disablePrjFixing = false;
        disableActualFixing = false;
        batchCompletionStatus = false;
        batchCompletionStatusForActuals  = false;
        batchProcessIds = new Set<Id>();
        batchProcessIdsOfActuals = new Set<Id>();
       
    }
   
    public PageReference doProjRPGFixing() {
        query1 = 'Select pse__Project_ID_Chain__c, Id From pse__Proj__c';
        batchObject1 = new BatchProcessingForInitialSetup(query1);
        batchprocessid1 = database.executeBatch(batchObject1) ;
       
        query2 = 'Select pse__Region_ID_Chain__c From pse__Region__c' ;
        batchObject2 = new BatchProcessingForInitialSetup(query2);
        batchprocessid2 = database.executeBatch(batchObject2) ;
       
        query3 = 'Select pse__Practice_ID_Chain__c From pse__Practice__c';
        batchObject3 = new BatchProcessingForInitialSetup(query3);
        batchprocessid3 = database.executeBatch(batchObject3) ;
       
 
        query4 = 'Select pse__Group_ID_Chain__c From pse__Grp__c' ;
        batchObject4 = new BatchProcessingForInitialSetup(query4);
        batchprocessid4 = database.executeBatch(batchObject4) ;
       
        batchProcessIds.add(batchprocessid1 );
        batchProcessIds.add(batchprocessid2 );
        batchProcessIds.add(batchprocessid3 );
        batchProcessIds.add(batchprocessid4 );
       
        disablePrjFixing = true;
        return null;
    }
   
    public void isbatchCompleted() {
        Boolean isCompletestatus = true;
        List<AsyncApexJob> aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                                 FROM AsyncApexJob WHERE ID =: batchProcessIds ];
       
        for (AsyncApexJob job : aaj) {
            if (job.Status != 'Completed') {
                isCompletestatus = false;
            }
        }
        if(isCompletestatus)
        {  
            displayActualBlock = true;
            batchCompletionStatus = true;
        }
        else
        {       
            displayActualBlock = false;
            batchCompletionStatus = false;
        }
    }
   
    public void isbatchCompletedForActuals() {
        batchCompletionStatusForActuals = true;
        List<AsyncApexJob> aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                                 FROM AsyncApexJob WHERE ID =: batchProcessIdsOfActuals ];
       
        for (AsyncApexJob job : aaj) {
            if (job.Status != 'Completed') {
                batchCompletionStatusForActuals = false;
            }
        }
    }
   
    public PageReference doActualsFixing() { 
        // Batch Processing for actuals
        query5 = 'Select pse__Unique_Name__c, pse__Time_Period__c, pse__Resource__c From pse__Resource_Actuals__c' ;
        BatchForFixingActuals batchForActual1 = new BatchForFixingActuals(query5 );
        batchIdForActual1 = database.executeBatch(batchForActual1 );
       
        query6 = 'Select pse__Unique_Name__c, pse__Time_Period__c, pse__Project__c From pse__Project_Actuals__c';
        BatchForFixingActuals batchForActual2 = new BatchForFixingActuals(query6 );
        batchIdForActual2 = database.executeBatch(batchForActual2 );
       
        query7 = 'Select pse__Unique_Name__c, pse__Time_Period__c, pse__Region__c From pse__Regional_Actuals__c';
        BatchForFixingActuals batchForActual3 = new BatchForFixingActuals(query7 );
        batchIdForActual3 = database.executeBatch(batchForActual3 );
       
        query8 = 'Select pse__Unique_Name__c, pse__Time_Period__c, pse__Practice__c From pse__Practice_Actuals__c';
        BatchForFixingActuals batchForActual4 = new BatchForFixingActuals(query8 );
        batchIdForActual4 = database.executeBatch(batchForActual4 );
       
        query9 = 'Select pse__Unique_Name__c, pse__Time_Period__c, pse__Group__c From pse__Group_Actuals__c';
        BatchForFixingActuals batchForActual5 = new BatchForFixingActuals(query9 );
        batchIdForActual5 = database.executeBatch(batchForActual5 );
       
        batchProcessIdsOfActuals.add(batchIdForActual1);
        batchProcessIdsOfActuals.add(batchIdForActual2);
        batchProcessIdsOfActuals.add(batchIdForActual3);
        batchProcessIdsOfActuals.add(batchIdForActual4);
        batchProcessIdsOfActuals.add(batchIdForActual5);
        disableActualFixing = true;
        return null;
    }
   
    public PageReference cancel() {
        return new PageReference('/home/home.jsp');
    }
   
}