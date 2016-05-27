/**
*   BulkTimeCardApprovalController
*   ==============================
*   Controller to allow bulk timecard Approval on a per company basis.
*
*   Alex Martin 30/10/2013
*  
*/
global with sharing class BulkTimeCardApprovalController 
{
    private Map<String, Schema.SObjectField> globalFieldDescribe = Schema.getGlobalDescribe().get('pse__Region__c').getDescribe().fields.getMap();

    public List<timecardWrapper> timecardWrapperList { get; set; }
    
    public Map<String, Schema.FieldSetMember> fieldSetMap { get; set; }
	//ffps_tcapp__TimecardApproval
    
    public c2g__codaCompany__c company { get; set; }

    public boolean all { get; set; }

    public BulkTimeCardApprovalController()
    {
        loadTCs();
    }    
        //We construct a query here (fancy that...);
        /*
        The timecard requires a field set to be constructed. this will be packaged. 
        users can come along and choose which fields they wish to display. 

        iterate through the fields, pick out the fields and the labels. We're going to use
        the labels for the columns of the table. 
        we also need to add them to the query for querying (duh?). 

        TODO: Construct where clause with Em to drill down and find the company. We know current company from function below. 
        */
        /*
        I made a boo boo. This entire idea is flawed. We want timecards not approved because salesforce say they're not approved.
        not because i deem them unapproved. This means using the approval process request API to return all approval requests and figuring out which
        ones have anything to do with timecards (Future version could be to display multiple tables showing different approval types but still 
        filter on company?)
        */


    public void loadTCs()
    {

        String query = 'Select ';
        //use SRP orgs only where you can identify the owner company on the timecard split. 
        //ffpsai__OwnerCompany__r.Name;
        fieldSetMap = new Map<String, Schema.FieldSetMember>(); 
        timecardWrapperList = new List<timecardWrapper>();

        try {
            List<Schema.FieldSetMember> fieldMembers = SObjectType.pse__Timecard_Header__c.FieldSets.TimecardApproval.getFields();

            for(Schema.FieldSetMember m : fieldMembers)
            {
                fieldSetMap.put(m.getLabel(), m);
                query += m.getFieldPath() + ', ';
            }

            List<Id> recordIdList = new List<Id>();
            for(ProcessInstance pi : getItemsToApprove())
            {
                recordIdList.add(pi.TargetObjectId);
            }  
                       
            c2g__codaCompany__c company = FFUtil.getCurrentCompany();
            if(company != null)
            {
                Id companyId = company.Id;
            }
       
            query = query.removeEnd(', ');
            query += ' from pse__Timecard_Header__c where Id in :recordIdList';

            //if it can't find the field, it will return all of the timecard headers.
            if(globalFieldDescribe.containsKey('ffpsai__OwnerCompany__c') && company != null)
            {
                query += ' and pse__Project__r.pse__Region__r.ffpsai__OwnerCompany__c = :companyId';
            }

            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, query));
            List<pse__Timecard_Header__c> timecardList = Database.query(query);   

            for(pse__Timecard_Header__c tch : timecardList)
            {
                timecardWrapperList.add(new TimecardWrapper(tch));
            } 

        } catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getmessage()));
        }
        //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, getItemsToApprove() + ''));
    }
 
    public PageReference approve()
    {
        List<pse__Timecard_Header__c> timecardsToApprove = new List<pse__Timecard_Header__c>();
        for(TimecardWrapper tcw : timecardWrapperList)
        {
            if(tcw.selected == true)
            {
                timecardsToApprove.add(tcw.timecard);
                //approveObj(tcw.timecard);
            }
        }
        try {
            //approveObj(new List<pse__Timecard_Header__c> ( timecardsToApprove ));
            if(checkBatches())
            {
                Id i = Database.executeBatch(new BulkTimecardApprovalBatch(new List<pse__Timecard_Header__c> ( timecardsToApprove), UserInfo.getSessionId()), 1);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Batch Started with id: ' + i));
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Too many batches running, please wait and try again'));
            } 
            
        } catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
            return null;
        }

        loadTCs();
        return ApexPages.currentPage();
    }

    public void approveObj(List<pse__Timecard_Header__c> objList)
    {
        List<ProcessInstanceWorkitem> workItemIdList = getWorkItemId(objList);
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

    public boolean checkBatches()
    {
        Integer MAX_BATCHES = 5;
        Integer runningBatchJobs = [
          select count()
          from AsyncApexJob
          where JobType = 'BatchApex'
          and status in ('Queued','Processing','Preparing')
        ];

        if(runningBatchJobs >= MAX_BATCHES) {
            return false;
        } else {
          return true;
        }        
    }  

    public class timecardWrapper
    {
        public pse__Timecard_Header__c timecard { get; set; }
        public boolean selected { get; set; }

        public timecardWrapper(pse__Timecard_Header__c timecard)
        {
            this.timecard = timecard;
            selected = false;
        }
    }

    public void selectAll()
    {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'No Work Item found for object list. Is there an approval process setup?'));
        for(TimecardWrapper tcw : timecardWrapperList)
        {
            tcw.selected = all;
        }
    }

    public List<ProcessInstance> getItemsToApprove()
    {
    	List<ProcessInstance> myApprovals = new List<ProcessInstance>(); 
        List<ProcessInstance> approvals = [ Select	Id, 
        											TargetObjectId, 
        											isDeleted, 
        											Status,
        											(Select Id, 
        													ProcessInstanceId, 
        													ActorId, 
        													Actor.Name, 
        													StepStatus, 
        													Comments 
                                						From 
                                							StepsAndWorkItems
                                						Where 
                                    						StepStatus = 'Pending'  
                                    						and	isDeleted = false 		
                                					Order By 
                                    						Createddate Desc )
                        						From 
                        							ProcessInstance
                        						Where
						                            isDeleted = false and
						                            Status = 'Pending'
                       		 				Order By 
                            						Createddate Desc ];     
                    
		if( !approvals.isEmpty() )
		{
            /*
            we're going to make a set of all the groups this user belongs too.
            */
            Id userId = UserInfo.getUserId();
            List<GroupMember> groupMembers = Database.query('select GroupId from GroupMember where UserOrGroupId = :userId');
            Set<Id> groupIds = new Set<Id> { UserInfo.getUserId() };
            for(GroupMember g : groupMembers)
            {
                groupIds.add(g.GroupId);
            }
			for( ProcessInstance approval : approvals )
			{
				boolean hasMyStep = false;
				if(!approval.StepsAndWorkitems.isEmpty()) 
				{	
					for ( ProcessInstanceHistory swi : approval.StepsAndWorkitems)
					{
						if( groupIds.contains(swi.ActorId))
						{
							hasMyStep = true;
							break; 
						}
					}
				}
				if(hasMyStep)
				{
					myApprovals.add(approval);
				}
			}
		}
        return myApprovals;   
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
/*
send the id to the function. get the id from another function based on the table row.
*/

}