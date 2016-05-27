trigger SalesInvoice on c2g__codaInvoice__c (after insert) 
{
	if(ConfigSettings.isCopyDocNumberToCustomerRef_Disabled()) return;
	
    map<id, c2g__codaInvoice__c> blankInvs = new map<id, c2g__codaInvoice__c>();
    for( c2g__codaInvoice__c inv : trigger.new)
    {
        if( inv.c2g__CustomerReference__c == null || inv.c2g__CustomerReference__c == '' )
        {
            blankInvs.put(inv.id, inv);
        }
    }

    map<id, c2g__codaInvoice__c> updateInvs;
    updateInvs = new map<id, c2g__codaInvoice__c>( [ select id, name, c2g__CustomerReference__c from c2g__codaInvoice__c where id in :blankInvs.keyset()] );
    for(c2g__codaInvoice__c inv : updateInvs.values() )
    {
        inv.c2g__CustomerReference__c = inv.name;
    }
    update updateInvs.values();
}