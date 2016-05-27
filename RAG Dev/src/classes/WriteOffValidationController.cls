global with sharing class WriteOffValidationController 
{
    private c2g__codaTransactionLineItem__c lineItem;
    public integer pass { get; set; }
    public integer total { get; set; }

    public c2g__codaCompany__c company0387 { get; set; }

    public WriteOffValidationController(ApexPages.StandardController ctrl) 
    {
        ctrl.addFields(new List<String> { 'c2g__OwnerCompany__c'});
        total = 1;
        pass=0;
        if(checkCompany((c2g__codaTransactionLineItem__c)ctrl.getRecord()))
        {
            pass = 1;
        }
    }

    public WriteOffValidationController(ApexPages.StandardSetController controller)
    {
    	list<c2g__codaTransactionLineItem__c> itemsToAction = new list<c2g__codaTransactionLineItem__c>();
        controller.addFields(new List<String> { 'c2g__OwnerCompany__c'});
        total = controller.getSelected().size();
        pass=0;
        for(Sobject o : controller.getSelected())
        {
        	c2g__codaTransactionLineItem__c tx = (c2g__codaTransactionLineItem__c)o;
            if( checkCompany(tx) )
            {
            	itemsToAction.add( tx );
                pass++;
            } 
        }
        controller.setSelected(itemsToAction );
    }

    private boolean checkCompany(c2g__codaTransactionLineItem__c line)
    {
        if(company0387 == null)
        {
            company0387 = FFUtil.getCurrentCompany();
        }

        if(line.c2g__OwnerCompany__c == company0387.Id)  
        {
            return true;
        } else {
            return false;
        }  
    }
}