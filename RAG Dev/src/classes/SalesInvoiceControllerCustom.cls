/**
*	SalesInvoiceControllerCustom
*	============================
*	Controller Extension for SalesInvoice print function, used by salesInvoicePrintCustom.page to build
* 	a custom list of invoice lines and their billing events based on the supplied Sales Invoice.
*
*	The lists are then used by various components to build summary values and aggregates for each 
* 	biilling event type Timecards/Expenses/Misc Adjustments/Milestones	
*
*	Luis Valenzuela 18/03/2013
*
*/
global with sharing class SalesInvoiceControllerCustom 
{
    global c2g__codaInvoice__c invoiceCustom { get; set {
    		invoiceCustom = value;
    		doMethod();
    	} }
    global List<c2g__codaInvoiceLineItem__c> invoiceLinesCustom {get; private set;}
    global List<pse__Billing_Event_Item__c> billingEventsCustom {get; private set;}
    
    global List<pse__Billing_Event_Item__c> timeCardBillingEventsCustom {get; private set;}
    global List<pse__Billing_Event_Item__c> mileStoneBillingEventsCustom {get; private set;}
    global List<pse__Billing_Event_Item__c> miscAdjsBillingEventsCustom {get; private set;}
    global List<pse__Billing_Event_Item__c> expensesBillingEventsCustom {get; private set;}
    global List<pse__Billing_Event_Item__c> otherBillingEventsCustom {get; private set;}

	global SalesInvoiceControllerCustom()
	{
		//doMethod();
	}    
    
    global SalesInvoiceControllerCustom( ApexPages.StandardController controller ) 
    {
    	    	
     	this.invoiceCustom = (c2g__codaInvoice__c) controller.getRecord();
     	doMethod();
    }    


    global void doMethod()
    {
     	
     	// separate lists for each billing event type and an other bucket to catch unexpected values
	    timeCardBillingEventsCustom = new list<pse__Billing_Event_Item__c>();  
	    mileStoneBillingEventsCustom = new list<pse__Billing_Event_Item__c>();  
	    miscAdjsBillingEventsCustom = new list<pse__Billing_Event_Item__c>();  
	    expensesBillingEventsCustom = new list<pse__Billing_Event_Item__c>();  
	    otherBillingEventsCustom = new list<pse__Billing_Event_Item__c>();  
     	
     	// Retrieve billing event information for invoice lines on supplied Sales invoice
 	 	invoiceLinesCustom = [	SELECT Id,
							           ffpsai__BillingEventItem__c,
							           ffpsai__BillingEventItem__r.pse__Object_Id__c,
							           ffpsai__BillingEventItem__r.pse__Category__c,
							           c2g__Invoice__r.c2g__InvoiceCurrency__r.Name,
							           c2g__Invoice__r.CatTitleProfFee__c,
									   c2g__Invoice__r.CatTitleOOPE__c, 
									   c2g__Invoice__r.CatTitleMiscAdj__c, 
									   c2g__Invoice__r.CatTitleDbChrg__c, 
									   c2g__Invoice__r.CatTitleAdminChrg__c,
							           c2g__Product__r.name,
							           c2g__Product__r.Category__c,
							           c2g__NetValue__c,
							           c2g__LineDescription__c,
							           c2g__UnitPrice__c,
							           c2g__Quantity__c,
							           CurrencyIsoCode
							      FROM c2g__codaInvoiceLineItem__c
							     WHERE c2g__Invoice__c = :invoiceCustom.Id];
  
 		Set<Id> billEventIds = new Set<Id>();
  		for(c2g__codaInvoiceLineItem__c invLin : invoiceLinesCustom)
  		{
    		billEventIds.add( invLin.ffpsai__BillingEventItem__c );
  		}
  		
 		billingEventsCustom = [  SELECT Id,
   										pse__Object_Id__c,
   										pse__Category__c
  								   FROM pse__Billing_Event_Item__c
 								  WHERE Id IN :billEventIds];
    	    
    	// Add bill events per catagory
  		for(pse__Billing_Event_Item__c billEvent : billingEventsCustom)
  		{
		    if( billEvent.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_TIMECARD )
		    {
				timeCardBillingEventsCustom.add(billEvent);
		    } 
		    else if( billEvent.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_MILESTONE )
		    {
				mileStoneBillingEventsCustom.add(billEvent);
		    } 
		    else if( billEvent.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_EXPENSE )
		    {
		      	expensesBillingEventsCustom.add(billEvent);
		    } 
		    else if( billEvent.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_MISCADJ )
		    {
		      	miscAdjsBillingEventsCustom.add(billEvent);
		    } 
		    else
		    {
		    	// Catch all for unexpected bill event types
		      	otherBillingEventsCustom.add(billEvent);
		    }
		}     	
    }
    
}