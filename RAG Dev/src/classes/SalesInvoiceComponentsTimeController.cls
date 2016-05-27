/**
*	SalesInvoiceComponentsTimeController
*	==================================
*	Controller responsible for creating list of timecards to be used by the SalesInvoicetime.component
* 	this controller uses a list of billingevents retrieved by the SalesInvoiceControllerCustom and then creates
* 	an ordered list to be added to the Sales invoice.
*
*	Luis Valenzuela 18/03/2013
*
*/
global with sharing class SalesInvoiceComponentsTimeController 
{

	// Invoice line billing events relating to timecards
	public list<pse__Billing_Event_Item__c> timecardBillEvents;
	public pse__Timecard__c[] timeCards{get; private set;}
	// Delimiter used for building sortable hashkey	
	public final String DELIM = RefData.DELIMITER;

	public list<pse__Billing_Event_Item__c> getTimecardBillEvents()
	{
		return timecardBillEvents;
	}
	
	public void setTimecardBillEvents( list<pse__Billing_Event_Item__c> billEvents)
	{

  		if( billEvents.isEmpty() ) return;
  		Set<Id> timeCardIds = new Set<Id>();
  		for(pse__Billing_Event_Item__c bei : billEvents)
  		{
    		timeCardIds.add( bei.pse__Object_Id__c );
  		}
  
  		// get timecards for supplied Billing Events
  		List<pse__Timecard__c> dbTimeCards = [ SELECT Id,
										           	  CurrencyIsoCode,
										           	  pse__Start_Date__c,
										           	  pse__End_Date__c,
										           	  pse__Total_Hours__c,
										           	  pse__Timecard_Header__r.pse__Bill_Rate__c,
										           	  pse__Total_Billable_Amount__c,
										           	  pse__Resource__c,
										           	  pse__Resource__r.LastName,
										           	  pse__Resource__r.FirstName
										         FROM pse__Timecard__c
										        WHERE Id IN :timeCardIds];
  		if( dbTimeCards.isEmpty() ) return;
  
  		String timeCardHashkey = '';
  		Map<String, pse__Timecard__c> timeCardHashkeyMap = new Map<String, pse__Timecard__c>();
  		for(pse__Timecard__c timeCard : dbTimeCards)
  		{
    		// Resource (Asc-1 (last,first)), Start Date (Asc-2), End Date (Asc-3), Hours, Rate, Amount}
    		// include record Id in the sort to ensure uniqueness
    		timeCardHashkey = timeCard.pse__Resource__r.LastName + DELIM +
                     			timeCard.pse__Resource__r.FirstName + DELIM +
                     				SalesInvoiceHelper.getDateStringYYYYMMDD(timeCard.pse__Start_Date__c) + DELIM +
                     					SalesInvoiceHelper.getDateStringYYYYMMDD(timeCard.pse__Start_Date__c) + DELIM +
                     						timeCard.Id;
    		timeCardHashkeyMap.put( timeCardHashkey, timeCard);
  		}
  		// sort the records
        this.timeCards = (list<pse__Timecard__c>) SalesInvoiceHelper.getSortedList( timeCardHashkeyMap );
  	}

} // end of class