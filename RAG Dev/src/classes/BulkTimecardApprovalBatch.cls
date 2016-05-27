global class BulkTimecardApprovalBatch implements Database.Batchable<pse__Timecard_Header__c>, Database.Stateful, Database.allowsCallouts {
	
	String query;
	private List<pse__Timecard_Header__c> timecardList;
    private String sessionId;
	
	global BulkTimecardApprovalBatch(List<pse__Timecard_Header__c> tcToApprove, String sId) {

		timecardList = tcToApprove;
        sessionId = sId;
	}

    global BulkTimecardApprovalBatch(List<pse__Timecard_Header__c> tcToApprove) {
        //do not use
    }    
	
	global List<pse__Timecard_Header__c> start(Database.BatchableContext BC) {
		return [Select Id from pse__Timecard_Header__c where Id in :timecardList];
		//return timecardList;
	}

   	global void execute(Database.BatchableContext BC, List<pse__Timecard_Header__c> scope) {
    
        String addr = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/ffps_0387/MethodsService/';

        HttpRequest req = new HttpRequest();
        req.setTimeout(60000); 
        req.setEndpoint( addr );
        req.setMethod('POST');
        req.setHeader('Authorization', 'OAuth ' + sessionId);
        req.setHeader('Content-Type','application/json; charset=UTF-8');
        req.setHeader('Accept','application/json');
        req.setHeader('Accept-Encoding','gzip');
        for(pse__Timecard_Header__c tc : scope)
        {
            Id tid = tc.id;
            req.setBody( tId );

            Http http = new Http();

            HttpResponse response = http.send(req);    

            String body = response.getBody();
            System.debug(body);
            if(response.getStatus()=='OK')
            {

            } else {
                throw new AppException('An error occurred inserting records: ' + body );
            } 
        }
        
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

    public List<ProcessInstanceWorkitem> getWorkItemId(List<pse__Timecard_Header__c> targetObjectId)
    {
        // Only 1 workItem should exist per object but ORDER BY added for safety
        try {
            List<ProcessInstanceWorkitem> workItem =[Select Id, 
            CreatedDate 
            from ProcessInstanceWorkitem p
            where ProcessInstance.TargetObjectId in :targetObjectId]; 
            return workItem;                      
        } catch(Exception e)
        {
            throw new AppException('No Work Item found for object list. Is there an approval process setup?');
            return new List<ProcessInstanceWorkItem>();
        }
    } // end of getWorkItemId	
	
}