global with sharing class SalesInvoiceComponentsSummaryController 
{

	global c2g__codaInvoiceLineItem__c[] originInvoicelines;
	global c2g__codaInvoiceLineItem__c[] milStonInvoiceLines;
	global c2g__codaInvoiceLineItem__c[] summaryInvoiceLines { get;	private set;}
	global pse__Billing_Event_Item__c[] mileStoneBillEvents;
	global pse__Milestone__c[] milestones{get; private set;}
	
	global String profFeeCatTitle;
	global String adminChrgCatTitle;
	global String oopeCatTitle;
	global String dbChrgCatTitle;
	global String miscAdjCatTitle;
  
  	global Decimal 	sumProfFee = 0, 
  					sumAdminCharge = 0, 
  					sumMilestones = 0, 
  					sumExpenses = 0, 
  					sumDbCharge = 0, 
  					sumMiscAdjustments = 0;
	
	global Integer 	countProfFee = 0, 
					countAdminCharge = 0, 
					countMilestones = 0, 
					countExpenses = 0, 
					countDbCharge = 0, 
					countMiscAdjustments = 0;
	
  	String currencyIsoCode = '';
	
	global list<c2g__codaInvoiceLineItem__c> getOriginInvoicelines( )
	{
		return originInvoicelines;
	}

	/**
	 *	Set Origin Invoice lines
	 *	------------------------
	 *	Method called by the component to initate the summarisation.
	 */
	global void setOriginInvoicelines( list<c2g__codaInvoiceLineItem__c> invLines )
	{
		if( originInvoicelines == null && !invLines.isEmpty())
		{
			originInvoicelines = invLines;
			catagoriseLines();
			handleMileStones();
			populateSummaryLines();			
		}	
	}

  		
  	/**
	 *	Catagorise Lines
	 *	----------------
	 *	Spearate lines into their invoice categories either by bill event type, milestone type or product.
	 */
	private void catagoriseLines()
	{	
  		this.milStonInvoiceLines = new List<c2g__codaInvoiceLineItem__c>();
	 	currencyIsoCode = originInvoicelines[0].c2g__Invoice__r.c2g__InvoiceCurrency__r.Name;
	 	
	 	profFeeCatTitle = originInvoicelines[0].c2g__Invoice__r.CatTitleProfFee__c;
		adminChrgCatTitle = originInvoicelines[0].c2g__Invoice__r.CatTitleAdminChrg__c;
		oopeCatTitle = originInvoicelines[0].c2g__Invoice__r.CatTitleOOPE__c;
		dbChrgCatTitle = originInvoicelines[0].c2g__Invoice__r.CatTitleDbChrg__c;
		miscAdjCatTitle = originInvoicelines[0].c2g__Invoice__r.CatTitleMiscAdj__c;
		
	 	profFeeCatTitle = (profFeeCatTitle == null || String.isBlank(profFeeCatTitle) ? refData.INVOICE_CATEGORY_PROF_FEES : profFeeCatTitle);
	 	adminChrgCatTitle = (adminChrgCatTitle == null || String.isBlank(adminChrgCatTitle) ? refData.INVOICE_CATEGORY_ADMIN_CHARGE : adminChrgCatTitle);
	 	oopeCatTitle = (oopeCatTitle == null || String.isBlank(oopeCatTitle) ? refData.INVOICE_CATEGORY_EXPENSE : oopeCatTitle);
	 	dbChrgCatTitle = (dbChrgCatTitle == null || String.isBlank(dbChrgCatTitle) ? refData.INVOICE_CATEGORY_DB_CHARGE : dbChrgCatTitle);
	 	miscAdjCatTitle = (miscAdjCatTitle == null || String.isBlank(miscAdjCatTitle) ? refData.INVOICE_CATEGORY_MISCADJ : miscAdjCatTitle);
									  
	  	/* Calculate summary totals */
  		for( c2g__codaInvoiceLineItem__c invLin : originInvoicelines)
  		{
  			if( invLin.c2g__Product__r != null && invLin.c2g__Product__r.Category__c != null )
		    {
			    // Professional Fees
			    if( invLin.c2g__Product__r != null && invLin.c2g__Product__r.Category__c == refData.INVOICE_CATEGORY_PROF_FEES )
			    {
			    	// log.debug('Prof Fee added' + invLin.c2g__NetValue__c);
			      	sumProfFee += invLin.c2g__NetValue__c;
			      	countProfFee++;
			    } 
				// Admin charge
			    else if( invLin.c2g__Product__r != null && invLin.c2g__Product__r.Category__c == refData.INVOICE_CATEGORY_ADMIN_CHARGE )
			    {
			    	//log.debug('Admin added' + invLin.c2g__NetValue__c);
			      	sumAdminCharge += invLin.c2g__NetValue__c;
			      	countAdminCharge++;
			    } 
			    // Expenses
			    else if( invLin.c2g__Product__r != null && invLin.c2g__Product__r.Category__c == refData.INVOICE_CATEGORY_EXPENSE )
			    {
			    	//log.debug('Expense added' + invLin.c2g__NetValue__c);
			      	sumExpenses += invLin.c2g__NetValue__c;
			      	countExpenses++;
			    } 
			    // DB charge
			    else if( invLin.c2g__Product__r != null && invLin.c2g__Product__r.Category__c == refData.INVOICE_CATEGORY_DB_CHARGE )
			    {
			    	//log.debug('Database added' + invLin.c2g__NetValue__c);
			      	sumDbCharge += invLin.c2g__NetValue__c;
			      	countDbCharge++;
			    } 
			    // Misc Adj
			    else 
			    {
			    	//log.debug('Misc Adjs added' + invLin.c2g__NetValue__c);
			      	sumMiscAdjustments += invLin.c2g__NetValue__c;
			      	countMiscAdjustments++;
			    } 
			} 
		    // If no product catagory specfied work out by either bill event type of milestone
		    else 
		    {
		        // Milestones
			    if( invLin.ffpsai__BillingEventItem__r != null && invLin.ffpsai__BillingEventItem__r.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_MILESTONE )
			    {
			    	// determine MS invoice lines to be handled by handleMileStones method.
					milStonInvoiceLines.add(invLin);
			      	countMilestones++;
			    } 
			    // Professional Fees
		    	else if( invLin.ffpsai__BillingEventItem__r != null && invLin.ffpsai__BillingEventItem__r.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_TIMECARD )
		    	{
			      	sumProfFee += invLin.c2g__NetValue__c;
			      	countProfFee++;
		    	}	
		    	// Expenses
		    	else if( invLin.ffpsai__BillingEventItem__r != null && invLin.ffpsai__BillingEventItem__r.pse__Category__c == RefData.BILL_EVENT_ITEM_CAT_EXPENSE )
		    	{
		    		sumExpenses += invLin.c2g__NetValue__c;
			      	countExpenses++;
		    	}
		    	// Misc Adjustments		    
			    else 
			    {
			    	log.debug('Misc added' + invLin.c2g__NetValue__c);
			      	sumMiscAdjustments += invLin.c2g__NetValue__c;
			      	countMiscAdjustments++;
			    }
		    }
		}
	}  
  
  
  	/**
	 *	Handle MileStones
	 *	-----------------
	 *	Build the summary lines according to the milestones.
	 */
	private void handleMileStones()
	{
  		if( milStonInvoiceLines.isEmpty() ) return;
  		Set<Id> milestoneIds = new Set<Id>();
  		map <Id, c2g__codaInvoiceLineItem__c> mileSton2InvLinMap = new map <Id, c2g__codaInvoiceLineItem__c> (); 		
					
		for( c2g__codaInvoiceLineItem__c invLin : milStonInvoiceLines )					     
		{
			mileSton2InvLinMap.put( invLin.ffpsai__BillingEventItem__r.pse__Object_Id__c , invLin );
		}					     
		milestoneIds = mileSton2InvLinMap.keyset();

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
    		
  		for( pse__Milestone__c milStn : dbMileStones)
  		{
		    if( milStn.Name == RefData.MS_NAME_PROF_FEE || milStn.Name == RefData.MS_NAME_SUBCONTRACTOR_FEE )
		    {
		    	log.debug('MS Prof Fee added' + mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c);
      			sumProfFee += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		      	countProfFee++;
		    } 
		    else if( milStn.Name == RefData.MS_NAME_SUBCONTRACTOR_EXP 
		    		||
		    		milStn.Name == RefData.MS_NAME_EXPENSES
		    		|| 
		    		milStn.Name == RefData.MS_NAME_PASS_THROUGH_COSTS )
		    {
		    	// log.debug('MS Expense added' + mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c);
		      	sumExpenses += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
		      	countExpenses++;
    		} 
		    else if( milStn.Name.contains( RefData.MS_NAME_ADMIN_CHARGE ) )
		    {
		    	// log.debug('MS Admin added' + mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c);
				sumAdminCharge += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
				countAdminCharge++;		    
			} 
		    else if( milStn.Name.contains( RefData.MS_NAME_DB_CHARGE ) )
		    {
		    	// log.debug('MS DB added' + mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c);
				sumDbCharge += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
				countDbCharge++;		    
		    } 
		    else 
		    {
		    	// log.debug('MS Misc added' + mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c);
				sumMiscAdjustments += mileSton2InvLinMap.get( milStn.id).c2g__NetValue__c;
				countMiscAdjustments++;		    
		    }    	
		}
	}

  
	/**
	 *	Populate Summary Lines
	 *	----------------------
	 *	Build a list of summary values to be displayed via the custom summary component.
	 */
	private void populateSummaryLines()
	{  
  		this.summaryInvoiceLines = new List<c2g__codaInvoiceLineItem__c>();
		
  		/* Build consolidated invoice lines summary */
  		// Professional Fees
  		if(countProfFee > 0)
  		{
			this.summaryInvoiceLines.add( new c2g__codaInvoiceLineItem__c( c2g__LineDescription__c = profFeeCatTitle,
																		   c2g__UnitPrice__c = sumProfFee,
																		   c2g__Quantity__c = 1,
																		   CurrencyIsoCode = currencyIsoCode) );
  		}
  		// Admin Charge
  		if(countAdminCharge > 0)
  		{
    		this.summaryInvoiceLines.add( new c2g__codaInvoiceLineItem__c( c2g__LineDescription__c = adminChrgCatTitle,
																      	   c2g__UnitPrice__c = sumAdminCharge,
																      	   c2g__Quantity__c = 1,
																           CurrencyIsoCode = currencyIsoCode) );
  		}
  		// Out of Poacket Expenses
  		if(countExpenses > 0)
  		{
    		this.summaryInvoiceLines.add( new c2g__codaInvoiceLineItem__c( c2g__LineDescription__c = oopeCatTitle,
																      	   c2g__UnitPrice__c = sumExpenses,
																      	   c2g__Quantity__c = 1,
																           CurrencyIsoCode = currencyIsoCode) );
  		}
  		// Database charge  		
  		if(countDbCharge > 0)
  		{
    		this.summaryInvoiceLines.add( new c2g__codaInvoiceLineItem__c( c2g__LineDescription__c = dbChrgCatTitle,
																      	   c2g__UnitPrice__c = sumDbCharge,
																      	   c2g__Quantity__c = 1,
																           CurrencyIsoCode = currencyIsoCode) );
  		}
  		// Adjustments 
   		if(countMiscAdjustments > 0)
  		{
    		this.summaryInvoiceLines.add(  new c2g__codaInvoiceLineItem__c( c2g__LineDescription__c = miscAdjCatTitle,
												      						c2g__UnitPrice__c = sumMiscAdjustments,
													      					c2g__Quantity__c = 1,
											      							CurrencyIsoCode = currencyIsoCode) );
  		}
  		
	} // end of Initialise


} // end of class