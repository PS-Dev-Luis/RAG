trigger ResourceRequestTrigger on pse__Resource_Request__c (before insert, before update, after insert, after delete, after update, after undelete) 
{
		
	try
	{
		FFUtil.getCurrentCompany();
	}
	catch(exception e)
	{
		String errorMsg = 'A single Company must be selected to create/update a Resource Request, please correct the following: \n' + e.getMessage();
		for (pse__Resource_Request__c r : Trigger.new) 
		{
			r.addError( errorMsg );
		}
		return;
	}
	
	/* BEFORE */
	if( trigger.isBefore )
	{
		set<id> oppIds = new set<id>();
		set<id> projIds = new set<id>();
		// Ensure Res Request currency in Accounting currencies 
		for(pse__Resource_Request__c rr : trigger.new )
		{
			oppIds.add(rr.pse__Opportunity__c);
			projIds.add(rr.pse__Project__c);
		}
		map<String, c2g__codaAccountingCurrency__c> accCurrIsos = CurrencyHelper.getAllAccCurrencies();
		map<id, Opportunity> opp2CurrencyMap = new map<id, Opportunity>( [   select id, 
																					name,
																					CurrencyIsoCode
																			   from Opportunity
																		 	  where id in :oppIds]);
		
		map<id, pse__Proj__c> proj2CurrencyMap = new map<id, pse__proj__c>( [ select id, 
																					 name,
																					 CurrencyIsoCode
																				from pse__Proj__c
																			   where id in :projIds]);
		
		for(pse__Resource_Request__c rr : trigger.new )
		{
			// Added functionality to add default currency after core dev screwed up v9 release by changing default
			if(rr.CurrencyIsoCode == null 
				|| 
				rr.pse__Suggested_Bill_Rate_Currency_Code__c == null
				||
				rr.pse__Average_Cost_Rate_Currency_Code__c == null )
			{
				string defaultCurr = ( opp2CurrencyMap.get(rr.pse__Opportunity__c) != null ? opp2CurrencyMap.get(rr.pse__Opportunity__c).CurrencyIsoCode : null);
				if(defaultCurr == null  )
				{
					defaultCurr = ( proj2CurrencyMap.get(rr.pse__Project__c) != null ? proj2CurrencyMap.get(rr.pse__Project__c).CurrencyIsoCode : null);
					if(defaultCurr == null  )
					{
						rr.addError( 'Resource\'s Opportunity or Project must have a valid accounting currency.');
					}
				}
				rr.CurrencyIsoCode = ( rr.CurrencyIsoCode != null ? rr.CurrencyIsoCode : defaultCurr);
				rr.pse__Suggested_Bill_Rate_Currency_Code__c = ( rr.pse__Suggested_Bill_Rate_Currency_Code__c != null ? rr.pse__Suggested_Bill_Rate_Currency_Code__c : defaultCurr);
				rr.pse__Average_Cost_Rate_Currency_Code__c = ( rr.pse__Average_Cost_Rate_Currency_Code__c != null ? rr.pse__Average_Cost_Rate_Currency_Code__c : defaultCurr);
				
			}
			if(!accCurrIsos.containsKey( rr.CurrencyIsoCode ) )
			{
				rr.CurrencyIsoCode.addError(
					'Currency ' + rr.CurrencyIsoCode + ' not in accounting currencies.');
			}
			if(!accCurrIsos.containsKey( rr.pse__Suggested_Bill_Rate_Currency_Code__c ) )
			{
				rr.pse__Suggested_Bill_Rate_Currency_Code__c.addError(
					'Currency ' + rr.pse__Suggested_Bill_Rate_Currency_Code__c + ' not in accounting currencies.');
			}
			if(!accCurrIsos.containsKey( rr.pse__Average_Cost_Rate_Currency_Code__c ) )
			{
				rr.pse__Average_Cost_Rate_Currency_Code__c.addError(
					'Currency ' + rr.pse__Average_Cost_Rate_Currency_Code__c + ' not in accounting currencies.');
			}
		}
		 
		// Handle Resource Request inserts, add reference to Projects available on referenced Opportunities
		if( !ConfigSettings.isAutoAssignOppResourcesToProject_Disabled() )
		{
			if(trigger.isInsert)
			{
				ResourceAllocationHandler.handleResourceRequestInsert( trigger.new );
			} 
		}	
	} // End of Before


	/* AFTER */
	else if( trigger.isafter )
	{
		if( !ConfigSettings.isRecalculateCostsOnOpportunity_Disabled() )
		{
			// insert/undelete 
			if( trigger.isInsert || trigger.isUndelete )
			{
				RecalculateOpportunityCostsHandler.recalculateInternalCosts( trigger.new );	
			} 
			// delete 
			else if(trigger.isDelete )
			{
				RecalculateOpportunityCostsHandler.recalculateInternalCosts( trigger.old );	
			} 
			// update 
			else if( trigger.isUpdate)
			{
				// only trigger on changes to calculation fields
				List<pse__Resource_Request__c> changedResReqs = new List<pse__Resource_Request__c>();
				for( integer i = 0;  i < trigger.new.size() ; i++  )
				{
					if ( trigger.new[i].pse__Resource_Role__c != trigger.old[i].pse__Resource_Role__c ||
					  		 trigger.new[i].pse__Suggested_Bill_Rate_Number__c != trigger.old[i].pse__Suggested_Bill_Rate_Number__c ||
						  		 trigger.new[i].pse__Suggested_Bill_Rate_Currency_Code__c != trigger.old[i].pse__Suggested_Bill_Rate_Currency_Code__c ||
						  		 	 trigger.new[i].pse__Average_Cost_Rate_Number__c != trigger.old[i].pse__Average_Cost_Rate_Number__c ||
							  		 	 trigger.new[i].pse__Average_Cost_Rate_Currency_Code__c != trigger.old[i].pse__Average_Cost_Rate_Currency_Code__c ||
							  		 	 	 trigger.new[i].pse__SOW_Hours__c != trigger.old[i].pse__SOW_Hours__c)
					{
						changedResReqs.add( trigger.new[i]);
					}
					else if (trigger.new[i].pse__Opportunity__c != trigger.old[i].pse__Opportunity__c )
					{
						changedResReqs.add( trigger.new[i]); // calculate new Opp Estimates
						// Add dummy reReq to trigger the old project recalc
						pse__Resource_Request__c dummyResReq =
							new pse__Resource_Request__c( pse__Opportunity__c = trigger.old[i].pse__Opportunity__c ); 
						changedResReqs.add( dummyResReq); 
					}		                                	 	
				}
				if(!changedResReqs.isEmpty())
				{
					RecalculateOpportunityCostsHandler.recalculateInternalCosts( changedResReqs );	
				}	
			} // End of upodate
		}
	} // End of After
}