/**
*	SalesInvoiceComponentsMaController
*	==================================
*	Controller responsible for creating list of misc Adjustments to be used by the SalesInvoiceMidcAdj.component
* 	this controller uses a list of billingevents retrieved by the SalesInvoiceControllerCustom and then creates
* 	an ordered list to be added to the Sales invoice.
* 
*	Luis Valenzuela 18/03/2013
*
*/
global with sharing class SalesInvoiceComponentsMaController 
{

	// Invoice line billing events relating to Miscellaneous Adjustments
	public list<pse__Billing_Event_Item__c> miscAdjBillEvents;
	public pse__Miscellaneous_Adjustment__c[] miscAdjustments{get; private set;}
	// Delimiter used for building sortable hashkey	
	public final String DELIM = RefData.DELIMITER;
	
	public list<pse__Billing_Event_Item__c> getMiscAdjBillEvents()
	{
		return miscAdjBillEvents;
	}
	
	public void setMiscAdjBillEvents( list<pse__Billing_Event_Item__c> billEvents)
	{
  		if( billEvents.isEmpty() ) return;
  		Set<Id> miscAdjsIds = new Set<Id>();
  		for(pse__Billing_Event_Item__c bei : billEvents)
  		{
    		miscAdjsIds.add( bei.pse__Object_Id__c);
  		}
  		if(miscAdjsIds.isEmpty()) return;
  
  		// get Miscellaneous Adjustments
  		List<pse__Miscellaneous_Adjustment__c> dbMiscAdjs = [ SELECT 	Id,
											           				CurrencyIsoCode,
													           		Name,
													           		pse__Effective_Date__c,
													           		pse__Amount__c,
													           		pse__Description__c
							      						   	  FROM	pse__Miscellaneous_Adjustment__c
													     	 WHERE 	Id IN :miscAdjsIds];
  		if(dbMiscAdjs.isEmpty()) return;
  
  		String miscAdjHashkey = '';
  		Map<String, pse__Miscellaneous_Adjustment__c> miscAdjHashkeyMap = new Map<String, pse__Miscellaneous_Adjustment__c>();
  		for(pse__Miscellaneous_Adjustment__c miscAdj : dbMiscAdjs)
  		{
			// Misc Adjustments {Misc Adjustment Name, Effective Date (Asc), Amount}
	    	// include record Id in the sort to ensure uniqueness
    		miscAdjHashkey = SalesInvoiceHelper.getDateStringYYYYMMDD(miscAdj.pse__Effective_Date__c) + DELIM +
            			         miscAdj.Name.rightPad(80).abbreviate(80) + DELIM + 
                 					miscAdj.Id;
    		miscAdjHashkeyMap.put( miscAdjHashkey, miscAdj);
  		}
  		// sort the records
    	this.miscAdjustments = (list<pse__Miscellaneous_Adjustment__c>) SalesInvoiceHelper.getSortedList(miscAdjHashkeyMap);
	} // end of initialise()

} // end of class