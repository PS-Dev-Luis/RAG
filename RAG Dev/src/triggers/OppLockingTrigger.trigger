trigger OppLockingTrigger on Opportunity (before update) {
    if(Trigger.isBefore && Trigger.isUpdate)
        new OppLockingTriggerHandler().validate(Trigger.new, Trigger.oldMap);
}