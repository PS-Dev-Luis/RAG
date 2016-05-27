trigger OpportunityTrigger on Opportunity (before insert, before update, after update) 
{	

	if( configSettings.isOpportunityCompanyValidation_Disabled() )
	{
		// Do not check for correct company and also do not revaluate the Resource Requests on the Opp
		return;
	}

	try
	{
		FFUtil.getCurrentCompany();
	}
	catch(exception e)
	{
		String errorMsg = 'A single Company must be selected to create/update an Opportunity, please correct the following: \n' + e.getMessage();
		for (Opportunity o : Trigger.new) 
		{
			o.addError( errorMsg );
		}
		return;
	}

	
	/* BEFORE */
	if( trigger.isBefore )
	{
		// Ensure Opp currency in Accounting currencies  
		map<String, c2g__codaAccountingCurrency__c> accCurrIsos = CurrencyHelper.getAllAccCurrencies();
		for(Opportunity opp : trigger.new )
		{
			if(!accCurrIsos.containsKey( opp.CurrencyIsoCode ) )
			{
				opp.CurrencyIsoCode.addError('Currency ' + opp.CurrencyIsoCode + ' not in accounting currencies.');
			}
		}
	}

	/* AFTER */	
	if( trigger.isUpdate && trigger.isAfter)
	{
		// only trigger on changes to currency field
		map<id, Opportunity> changedOpps = new map<id, Opportunity>();
		for( integer i = 0;  i < trigger.new.size() ; i++  )
		{
			if ( trigger.new[i].CurrencyIsoCode != trigger.old[i].CurrencyIsoCode) 
			{
				changedOpps.put( trigger.new[i].Id, trigger.newMap.get(trigger.new[i].Id) );
			}
			if(!changedOpps.isEmpty())
			{
				RecalculateOpportunityCostsHandler.recalculateInternalCosts( changedOpps );	
			}	
		}
	}
}