public with sharing class OppLockingTriggerHandler {
    
    private Map<String, Schema.SObjectField> globalFieldDescribe = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
    private List<String> fieldList = new List<String> {
        'Amount',
        'Proposed_Internal_Labor_Cost__c',
        'Subcontractor_Labour_Cost__c',
        'Subcontractor_Expenses__c',
        'Percentage_OOPE_Charge_Applied__c',
        'Percentage_Admin_Expense_Charge_Applied__c',
        'Percentage_Database_Charge_Applied__c',
        'Pass_Through_Costs__c',
        'Total_Budget_Costs__c',
        'Calculated_Internal_Labour_Cost__c',
        'Calculated_Subcontractor_Labour_Cost__c',
        'Subcontractor_Expenses2__c',
        'Calculated_OOPE_Charge__c',
        'Calculated_Admin_Expense_Charge__c',
        'Calculated_Database_Charge__c',
        'Pass_Through_Costs2__c',
        'Total_Proposed_Budget_Cost__c',
        'Proposed_Total_Fee__c',
        'Proposed_Expense2__c',
        'Recovery_Rate__c'
    };

    public void validate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {

        for(Opportunity o : newOpps)
        {
            if(o.Locked__c == true)
            {
                Opportunity oldOpp = oldOpps.get(o.Id);
                for(String field : fieldList)
                {
                    //throw new AppException(globalFieldDescribe.containsKey(field) + 'buu: ' + o.get(field) + ' :: ' + oldOpp.get(field) + ' :: ' + field);
                    if(globalFieldDescribe.containsKey(field) && oldOpp.get(field) != o.get(field))
                    {
                        o.addError('Record locked');
                    }
                }
            }
        }
    }
}