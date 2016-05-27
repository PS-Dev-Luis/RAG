trigger SalesCreditNote on c2g__codaCreditNote__c (after insert) 
{   
	if(ConfigSettings.isCopyDocNumberToCustomerRef_Disabled()) return;
	
    map<id, c2g__codaCreditNote__c> blankCreds = new map<id, c2g__codaCreditNote__c>();
    for( c2g__codaCreditNote__c cNote : trigger.new)
    {
        if( cNote.c2g__CustomerReference__c == null || cNote.c2g__CustomerReference__c == '' )
        {
            blankCreds.put(cNote.id, cNote);
        }
    }

    map<id, c2g__codaCreditNote__c> updateCreds;
    updateCreds = new map<id, c2g__codaCreditNote__c>( [ select id, 
                                                                c2g__Invoice__r.name, 
                                                                c2g__CustomerReference__c 
                                                           from c2g__codaCreditNote__c 
                                                          where id in :blankCreds.keyset()] );
    for(c2g__codaCreditNote__c cred : updateCreds.values() )
    {
        cred.c2g__CustomerReference__c = ( cred.c2g__Invoice__r != null ? cred.c2g__Invoice__r.name : null) ;
    }
    update updateCreds.values();
    
}