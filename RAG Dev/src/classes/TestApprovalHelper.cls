/**
 *	TestApprovalHelper
 *	==================
 *	Helper class to wrap the standard Salesforce Approval process.
 *
 *	Luis Valenzuela 20/02/2013
 *
 **/
@isTest (seeAllData = true)
public with sharing class TestApprovalHelper 
{
	
	// Submit the Object onto an existing Approval Process
	// Dev env has Approval process set up and next
	// Approver automatically set to an administrative user.
	public static boolean submitObjForApproval(sObject obj)
	{
		Approval.ProcessSubmitRequest req1 =  new Approval.ProcessSubmitRequest();
	    req1.setComments('Submitting object for approval using TestApprovalHelper.');
	    req1.setObjectId(obj.id);
		try
		{
			Approval.ProcessResult result = Approval.process(req1);
			return true;
		}
		catch (exception e)
		{
			Log.warn( 'Approval Process not set up for Object.');
			return false; //  set flag manually
		}	
	}
	
	// Approve the Object on the Approval process setup in the Dev env
	public static boolean approveObj(sObject obj)
	{
		Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Approving request using TestApprovalHelper.');
        req.setAction('Approve');
        Id workItemId = getWorkItemId(obj.id);
        if(workItemId == null)
        {
			Log.warn( 'Failed to retrieve ProcessWorkitemRequest for created Approval.' );
			return false; // set flag manually
		}
        else
        {
            req.setWorkitemId(workItemId);
            // Submit the request for approval
            try
            {
	            Approval.ProcessResult result =  Approval.process(req);
	            return true;	
            }
    		catch(Exception e)
    		{
    			Log.warn( 'Failed to Approve Object.');
    			return false; // set flag manually
    		}        
        }
	}
	
	//Get ProcessInstanceWorkItemId using SOQL
    public static Id getWorkItemId(Id targetObjectId)
    {
    	// Only 1 workItem should exist per object but ORDER BY added for safety
        ProcessInstanceWorkitem workItem =[Select Id, 
    											  CreatedDate 
											 from ProcessInstanceWorkitem p
    										where ProcessInstance.TargetObjectId =: targetObjectId
    									 order by CreatedDate DESC LIMIT 1];
       
        return (workItem != null) ? workItem.Id : null ;
        
    } // end of getWorkItemId
}