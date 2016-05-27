trigger MiscAdjustTrigger on pse__Miscellaneous_Adjustment__c ( before insert, before update, after insert, after update ) 
{

	c2g__codaCompany__c currComp;

	/* BEFORE */
	if( trigger.isBefore && TriggerContext.miscAdj_hasRan == false )
	{
		// Validation checks 
		if( !checkSingleCompany() ) return;
		validateAccountingCurrencies();
		validateProjects();
	
	} // End of Before

	
	
	/* AFTER */
	if( trigger.isAfter )
	{
		// Journal Creation 
		if( !ConfigSettings.isGenerateProjectJournal_Disabled() && TriggerContext.miscAdj_hasRan == false )
		{
			
			List<pse__Miscellaneous_Adjustment__c> journalMiscAdjs = new List<pse__Miscellaneous_Adjustment__c>();
			for( integer i = 0; i < trigger.new.size(); i++ )
			{
				// After update check that the Generate Journal field has changed, this should only ever
				// occur on the first instance of Misc Adjustment approval.  After insert check Generate Journal set.
				if( trigger.isUpdate && trigger.new[i].Generate_Journal__c && !trigger.old[i].Generate_Journal__c )
				{	
					journalMiscAdjs.add(trigger.new[i]);
				} 
				else if ( trigger.isInsert && trigger.new[i].Generate_Journal__c )
				{
					journalMiscAdjs.add(trigger.new[i]);
				}
			}
			if(!journalMiscAdjs.isEmpty())
			{
				TriggerContext.miscAdj_hasRan = true; 
				/* Trigger Action */
				JournalCreationHelper.createJournal(journalMiscAdjs);
			}
		}//End of Journal Creation
									
	}// end of isAfter
	
	
	
	/**********************/
	/* VALIDATION METHODS */
	
	/**
	 * Validation method to ensure that exactly 1 company selected.
	 **/
	public static boolean checkSingleCompany()
	{
		// log.addLog('CHECKING COMPANY ' + TriggerContext.counter);
		// Check single Valid Company
		try
		{
			currComp = FFUtil.getCurrentCompany();	
		}
		catch(exception e)
		{
			String errorMsg = 'A single Company must be selected to create/update a Project, please correct the following: \n' + e.getMessage();
			for (pse__Miscellaneous_Adjustment__c p : Trigger.new) 
			{
				p.addError( errorMsg );
			}
			return false;
		}
		return true;		
	} //  end of check Single company


	/**
	 * Validation method to ensure project currency in accounting currecies.
	 **/
	public static void validateAccountingCurrencies()
	{
		// Check Proj currency in Accounting currencies
		map<String, c2g__codaAccountingCurrency__c> accCurrIsos = CurrencyHelper.getAllAccCurrencies();
		for(pse__Miscellaneous_Adjustment__c miscAdj : trigger.new )
		{
			if(!accCurrIsos.containsKey( miscAdj.CurrencyIsoCode ) )
			{
				miscAdj.CurrencyIsoCode.addError('Currency ' + miscAdj.CurrencyIsoCode + ' not in accounting currencies.');
			}
		}
	}// end of checkAccountingCurrencies


	/**
	 * Validation method to ensure project's Company is same as the users.
	 **/
	public static void validateProjects()
	{
		currComp = FFUtil.getCurrentCompany();
		
		// Check Region and Practice populated, necessary for proj code.
		set<id> projIds = new set <id>();
		map<id,integer> projTomiscAdjMap = new map<id,integer>(); 
		
		for( integer i = 0; i < trigger.new.size(); i++  )
		{
			pse__Miscellaneous_Adjustment__c miscAdj = trigger.new[i];
			projIds.add( miscAdj.pse__Project__c );
			projTomiscAdjMap.put( miscAdj.pse__Project__c, i );
		}

		// Retrieve list of regions.ownerComapanies for the projects.
		map <id, pse__Proj__c> projMap = new map<id,pse__Proj__c>( [ Select	id,
																			pse__Practice__c,
																			pse__Region__r.ffpsai__OwnerCompany__r.id,
																			pse__Region__r.ffpsai__OwnerCompany__r.Name
												  								   from pse__Proj__c
												 			 					  where id in :projIds]);
		// Ensure practice and region are set
		for( pse__Proj__c proj : projMap.values() )
		{
			if( proj.pse__Practice__c == null )
			{
				log.debug(' Proje map' + projTomiscAdjMap );
				log.debug(' trigger map' + trigger.newMap );
				trigger.new[ projTomiscAdjMap.get(proj.id) ].addError('Practice must be set on Project.');
			}
			if( proj.pse__Region__c == null )
			{
				trigger.new[ projTomiscAdjMap.get(proj.id) ].addError('Region must be set on Project.');
			}
		}
		

		// Check user's company against projects companies
		for( pse__Miscellaneous_Adjustment__c miscAdj : trigger.new )
		{
			pse__Proj__c proj = projMap.get( miscAdj.pse__Project__c );
			if( proj == null )
			{
				trigger.new[ projTomiscAdjMap.get(proj.id) ].addError('Project must be set on Misc Adj.');
			}
			
			c2g__codaCompany__c projComp = ( proj.pse__Region__r != null ? proj.pse__Region__r.ffpsai__OwnerCompany__r : null ); 
			if( projComp == null || projComp.Id != currComp.Id )
			{
				String errorMsg = (projComp == null ? 'Entity(Region) must have a valid Owner Company.'
													: 'You cannot insert/update this project unless your current Company is set as \"' + projComp.Name + '\".'  ) ;
				trigger.new[ projTomiscAdjMap.get(proj.id) ].addError( errorMsg );
			}
		} 
	} // End of checkProjectCompany

}