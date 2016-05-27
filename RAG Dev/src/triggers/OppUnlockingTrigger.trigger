trigger OppUnlockingTrigger on pse__Proj__c (after update) {
    if(Trigger.isUpdate)
        new OppUnlockingTriggerHandler().validate(Trigger.new);
}