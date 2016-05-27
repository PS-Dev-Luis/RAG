trigger TimecardHeaderTrigger on pse__Timecard_Header__c (before insert, before update, after insert, after update) 
{
	static boolean hasRan = false;
	
	c2g__codaCompany__c currComp;
		
	/* BEFORE */
	if( trigger.isBefore && hasRan == false )
	{
		// Validation checks
		if( !checkSingleCompany() ) return;
		checkAccountingCurrencies();
	} // End of Before
	
	/* AFTER */
	// Journal Creation [Story 10 of CD0387]
	if( trigger.isAfter  && hasRan == false )
	{
		if(!ConfigSettings.isGenerateTimecardJournal_Disabled())
		{
			checkProjectCompany();
			
			List<pse__Timecard_Header__c> journalTimecardHdrs = new List<pse__Timecard_Header__c>();
			for( integer i = 0; i < trigger.new.size(); i++ )
			{
				// After update check that the Generate Journal field has changed, this should only ever
				// occur on the first instance of timecard approval. After insert check Genrate Journal set.
				if( trigger.isUpdate && trigger.new[i].Generate_Journal__c && !trigger.old[i].Generate_Journal__c)
				{	
						journalTimecardHdrs.add(trigger.new[i]);
				} 
				else if ( trigger.isInsert && trigger.new[i].Generate_Journal__c )
				{
					journalTimecardHdrs.add(trigger.new[i]);
				}
			}
			if(!journalTimecardHdrs.isEmpty())
			{
				JournalCreationHelper.createJournal(journalTimecardHdrs);
			}
		}
		hasRan = true;
	}// end of After	
	

	/* VALIDATION METHODS */
	
	/**
	 * Validation method to ensure that exactly 1 company selected.
	 **/
	public static boolean checkSingleCompany()
	{	
		// Check single Valid Company
		try
		{
			currComp = FFUtil.getCurrentCompany();	
		}
		catch(exception e)
		{
			String errorMsg = 'A single Company must be selected to create/update a Timecard, please correct the following: \n' + e.getMessage();
			for (pse__Timecard_Header__c t : Trigger.new) 
			{
				t.addError( errorMsg );
			}
			return false;
		}
		return true;
	} //  end of check Single company

	/**
	 * Validation method to ensure project currency in accounting currecies.
	 **/
	public static void checkAccountingCurrencies()
	{
		// Ensure Timecard currency in Accounting currencies
		map<String, c2g__codaAccountingCurrency__c> accCurrIsos = CurrencyHelper.getAllAccCurrencies();
		for(pse__Timecard_Header__c tch : trigger.new )
		{
			if(!accCurrIsos.containsKey( tch.CurrencyIsoCode ) )
			{
				tch.CurrencyIsoCode.addError('Currency ' + tch.CurrencyIsoCode + ' not in accounting currencies.');
			}
		}
	}// end of checkAccountingCurrencies


	/**
	 * Validation method to ensure project's Company is same as the users.
	 **/
	public static void checkProjectCompany()
	{
		currComp = FFUtil.getCurrentCompany();
		// Retrieve list of project.regions.ownerComapanies for the timecards.
		list <pse__Timecard_Header__c> tcRegions = [ Select id, 
															pse__Project__r.pse__Region__r.ffpsai__OwnerCompany__r.id,
															pse__Project__r.pse__Region__r.ffpsai__OwnerCompany__r.Name
											  		   from pse__Timecard_Header__c
											  		  where id in :Trigger.newMap.keySet()];
		
		// Check user's company against projects
		for (pse__Timecard_Header__c tc : tcRegions ) 
		{
			
			c2g__codaCompany__c tcComp = tc.pse__Project__r.pse__Region__r.ffpsai__OwnerCompany__r;
			if( tcComp == null || tcComp.Id != currComp.Id )
			{
				String errorMsg = (tcComp == null ? 'You cannot insert/update this timecard unless the Entity(Region) is set and has a valid Owner Company.'
													: 'You cannot insert/update this timecard unless your current Company is set as \"' + tcComp.Name + '\".'  ) ;
				trigger.newMap.get(tc.id).addError( errorMsg );
			}
		}
	} // End of checkProjectCompany
	
}