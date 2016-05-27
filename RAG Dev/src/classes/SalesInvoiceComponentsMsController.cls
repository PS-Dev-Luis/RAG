/**
*	SalesInvoiceComponentsMsController
*	==================================
*	Controller responsible for creating list of milestones to be used by the SalesInvoiceMilestone.component
* 	this controller uses a list of billingevents retrieved by the SalesInvoiceControllerCustom and then creates
* 	an ordered list to be added to the Sales invoice.
*
*	Luis Valenzuela 18/03/2013
*
*/
global with sharing class SalesInvoiceComponentsMsController 
{

	public static final String PROFFEES_DESC = 'Professional Fees';
	public static final String OOPE_DESC = 'Out of pocket expenses';
	public static final String ADMIN_DESC = 'Admin charges';
	public static final String DB_DESC = 'Database charges';
	public static final String OTHER_DESC = 'Other charges';
	
	// Invoice line billing events relating to Milestones
	public list<pse__Billing_Event_Item__c> mileStoneBillEvents;
	public pse__Milestone__c[] milestones{get; private set;}
	// Delimiter used for building sortable hashkey	
	public final String DELIM = RefData.DELIMITER;
	
	public list<pse__Billing_Event_Item__c> getMileStoneBillEvents()
	{
		return mileStoneBillEvents;
	}
  
	public void setMileStoneBillEvents(list<pse__Billing_Event_Item__c> billEvents)
	{
  		if( billEvents.isEmpty() ) return;
  		Set<Id> milestoneIds = new Set<Id>();
  		Set<Id> billEventIds = new Set<Id>();
  		map <Id, c2g__codaInvoiceLineItem__c> mileSton2InvLinMap = new map <Id, c2g__codaInvoiceLineItem__c> ();
  		
  		list<c2g__codaInvoiceLineItem__c> milStonInvoiceLines;
  		
  		for(pse__Billing_Event_Item__c bei : billEvents)
  		{
    		milestoneIds.add( bei.pse__Object_Id__c );
    		billEventIds.add(bei.id);
  		}
  		
  		// Get the invoice line values as these may have been changed after the Bill Events have been passed.
  	 	milStonInvoiceLines = [	SELECT Id,
							           ffpsai__BillingEventItem__c,
							           ffpsai__BillingEventItem__r.pse__Object_Id__c,
							           ffpsai__BillingEventItem__r.pse__Category__c,
							           
							           c2g__NetValue__c,
							           CurrencyIsoCode
							      FROM c2g__codaInvoiceLineItem__c
							     WHERE ffpsai__BillingEventItem__c in :billEventIds];
							     
		for( c2g__codaInvoiceLineItem__c invLin : milStonInvoiceLines )					     
		{
			mileSton2InvLinMap.put(invLin.ffpsai__BillingEventItem__r.pse__Object_Id__c , invLin );
		}					     

  		// get Milestones for supplied Billing Events
  		List<pse__Milestone__c> dbMileStones = [ SELECT Id,
							 	          			 	CurrencyIsoCode,
										    	  	 	Name,
									        	   	 	pse__Actual_Date__c,
										           	 	pse__Milestone_Amount__c,
										           	 	pse__Description__c
									       		  FROM  pse__Milestone__c
										      	 WHERE  Id IN :milestoneIds ];
										      	 
  		if( dbMileStones.isEmpty() ) return;
  
  		decimal profFeeMsSum = 0.0;
  		decimal oopeMsSum = 0.0;
  		decimal adminMsSum = 0.0;
  		decimal dbMsSum = 0.0;
  		decimal otherMsSum = 0.0;
  		
  		for( pse__Milestone__c milStn : dbMileStones)
  		{
		    if( milStn.Name == RefData.MS_NAME_PROF_FEE || milStn.Name == RefData.MS_NAME_SUBCONTRACTOR_FEE )
		    {
		      	profFeeMsSum += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		    } 
		    else if( milStn.Name == RefData.MS_NAME_SUBCONTRACTOR_EXP 
		    		||
		    		milStn.Name == RefData.MS_NAME_EXPENSES
		    		|| 
		    		milStn.Name == RefData.MS_NAME_PASS_THROUGH_COSTS )
		    {
		      	oopeMsSum += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		    } 
		    else if( milStn.Name.contains( RefData.MS_NAME_ADMIN_CHARGE ) )
		    {
		      	adminMsSum += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		    } 
		    else if( milStn.Name.contains( RefData.MS_NAME_DB_CHARGE ) )
		    {
		      	dbMsSum += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		    } 
		    else 
		    {
		  		otherMsSum += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		    }    	
		}
  		
  		milestones = new list<pse__Milestone__c>();
  		// Create custom Milestones to represent consolidated milestone summary
  		if(profFeeMsSum > 0)
  		{
			this.milestones.add( new pse__Milestone__c( name = PROFFEES_DESC,
													    pse__Milestone_Amount__c = profFeeMsSum ));
  		}
  		if(oopeMsSum > 0)
  		{
			this.milestones.add( new pse__Milestone__c( name = OOPE_DESC,
													    pse__Milestone_Amount__c = oopeMsSum ));
  		}
  		if(adminMsSum > 0)
  		{
			this.milestones.add( new pse__Milestone__c( name = ADMIN_DESC,
													    pse__Milestone_Amount__c = adminMsSum ));
  		}
  		if(dbMsSum > 0)
  		{
			this.milestones.add( new pse__Milestone__c( name = DB_DESC,
													    pse__Milestone_Amount__c = dbMsSum ));
  		}
  		if(otherMsSum > 0)
  		{
			this.milestones.add( new pse__Milestone__c( name = OTHER_DESC,
													    pse__Milestone_Amount__c = otherMsSum ));
  		}
  	}

} // end of class