@RestResource(urlMapping='/MethodsService/*')
global with sharing class BulkApprovalWebService {
	@HttpPost
	webservice static void approveObj()
	{
		//MethodsServiceResponse response = new MethodsServiceResponse();

		Id id = System.RestContext.request.requestBody.toString();	
			
        List<ProcessInstanceWorkitem> workItemIdList = getWorkItemId(new List<Id> { id });
        List<Approval.ProcessWorkItemRequest> approvalRequestList = new List<Approval.ProcessWorkItemRequest>();
        for(ProcessInstanceWorkItem wI : workItemIdList)
        {
            Approval.ProcessWorkItemRequest req = new Approval.ProcessWorkItemRequest();
            req.setComments('Approving request using Bulk Timecard Approval.');
            req.setAction('Approve');
            approvalRequestList.add(req);  
            req.setWorkitemId(wI.Id);          
        }
        //Id workItemId = getWorkItemId(obj.id);
        if(workItemIdList == null)
        {
            //return false; // set flag manually
        } else {
            // Submit the request for approval
            List<Approval.ProcessResult> result =  Approval.process(approvalRequestList);     
        }		
	}

    public static List<ProcessInstanceWorkitem> getWorkItemId(List<Id> targetObjectId)
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