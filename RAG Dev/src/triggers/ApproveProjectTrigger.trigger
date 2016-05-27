trigger ApproveProjectTrigger on pse__Proj__c (after update) {
    new ApproveProjectTriggerHandler().validate(Trigger.new);
}