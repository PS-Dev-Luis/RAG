trigger ProjectTrigger on pse__Proj__c (before insert, before update, after insert, after update) 
{
	if(trigger.isBefore)
	{
		TriggerContext.enteringProjTrigger();
	}

	c2g__codaCompany__c currComp;

	/* BEFORE */
	if( trigger.isBefore && TriggerContext.proj_hasRanValidation == false )
	{
		TriggerContext.proj_hasRanValidation = true;

		// Validation checks 
		if( !checkSingleCompany() ) return;
		validateAccountingCurrencies();
		validateProjects();
	
	} // End of Before

	
	
	/* AFTER */
	if( trigger.isAfter )
	{
		if( trigger.isInsert)
		{
			// Create project codes
			if( TriggerContext.proj_hasRanProjectCodeCreation == false )
			{
				TriggerContext.proj_hasRanProjectCodeCreation = true;	
				ProjectCodeHandler.createCodes(trigger.newMap);
			}
			// Dimension 3 Generation, necessary for WIP reporting 
			if( !ConfigSettings.isGenerateProjectDimension_Disabled() && TriggerContext.proj_hasRanDimCreation == false )
			{
				TriggerContext.proj_hasRanDimCreation = true;	
				DimensionCreationHandler.handleProjectInsert( trigger.newMap );
			}
			// Resource Request Allocation [Req 2.3 of CD0387], 
			if( !ConfigSettings.isAutoAssignOppResourcesToProject_Disabled() && TriggerContext.proj_hasRanResourceAllocation == false )
			{
				TriggerContext.proj_hasRanResourceAllocation = true;
				ResourceAllocationHandler.handleProjectInsert( trigger.new );
			}
		}
		

		// Milestone Creation [Req 2.4 - 2.9 of CD0387] 
		if( !ConfigSettings.isGenerateProjectMilestones_Disabled() && TriggerContext.proj_hasRanMsCreation == false )
		{
			List<pse__Proj__c> milestoneProjs = new List<pse__Proj__c>();
			for( integer i = 0; i < trigger.new.size(); i++ )
			{
				// After update check that the Generate Milestones field has changed, this should only ever
				// occur on the first instance of Project approval.  After insert check whether Generate Milestone set.
				if( trigger.isUpdate && trigger.new[i].Generate_Milestones__c && !trigger.old[i].Generate_Milestones__c )
				{	
					milestoneProjs.add(trigger.new[i]);
				} 
				else if ( trigger.isInsert && trigger.new[i].Generate_Milestones__c )
				{
					milestoneProjs.add(trigger.new[i]);
				}
			}
			if( !milestoneProjs.isEmpty() )
			{ 
				// Add errors to projects
				TriggerContext.proj_hasRanMsCreation = true;
				Map<Id, String> milstoneErrorResult = MilestoneCreationHelper.createMilestones( milestoneProjs );
				for( Id projId : milstoneErrorResult.keySet() )
				{
					trigger.newMap.get(projId).addError( milstoneErrorResult.get(projId) );
				}
			}
		}// End of Milestone Creation
	

		// Journal Creation [Story 10 of CD0387]
		if( !ConfigSettings.isGenerateProjectJournal_Disabled() && TriggerContext.proj_hasRanJournalCreation == false )
		{
			List<pse__Proj__c> journalProjs = new List<pse__Proj__c>();
			for( integer i = 0; i < trigger.new.size(); i++ )
			{
				// After update check that the Generate Journal field has changed, this should only ever
				// occur on the first instance of Project approval.  After insert check Generate Journal set.
				if( trigger.isUpdate && trigger.new[i].Generate_Journal__c && !trigger.old[i].Generate_Journal__c )
				{	
					journalProjs.add(trigger.new[i]);
				} 
				else if ( trigger.isInsert && trigger.new[i].Generate_Journal__c )
				{
					journalProjs.add(trigger.new[i]);
				}
			}
			if(!journalProjs.isEmpty())
			{
				TriggerContext.proj_hasRanJournalCreation = true;
				JournalCreationHelper.createJournal(journalProjs);
			}
		}//End of Journal Creation
									
	}// end of isAfter
	
	if(trigger.isAfter)
	{
		TriggerContext.leavingProjTrigger();
	}
	
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
			for (pse__Proj__c p : Trigger.new) 
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
		for(pse__Proj__c proj : trigger.new )
		{
			if(!accCurrIsos.containsKey( proj.CurrencyIsoCode ) )
			{
				proj.CurrencyIsoCode.addError('Currency ' + proj.CurrencyIsoCode + ' not in accounting currencies.');
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
		set<id> regionIds = new set <id>();
		for(pse__Proj__c proj : trigger.new )
		{
			if( proj.pse__Practice__c == null )
			{
				proj.pse__Practice__c.addError('Practice must be set for generation of Project Code');
			}
			if( proj.pse__Region__c == null )
			{
				proj.pse__Region__c.addError('Region must be set for generation of Project Code');
			}
			else
			{
				regionIds.add( proj.pse__Region__c );
			}
		}
		
		// Retrieve list of regions.ownerComapanies for the projects.
		map <id, pse__Region__c> projRegions = new map<id,pse__Region__c>( [ Select id, 
																					ffpsai__OwnerCompany__r.id,
																					ffpsai__OwnerCompany__r.Name
											  								   from pse__Region__c
											 			 					  where id in :regionIds]);

		// Check user's company against projects companies
		for (pse__Proj__c p : trigger.new ) 
		{
			pse__Region__c projReg = projRegions.get( p.pse__Region__c );
			c2g__codaCompany__c projComp = ( projReg != null ? projReg.ffpsai__OwnerCompany__r : null ); 
			if( projComp == null || projComp.Id != currComp.Id )
			{
				String errorMsg = (projComp == null ? 'Entity(Region) must have a valid Owner Company.'
													: 'You cannot insert/update this project unless your current Company is set as \"' + projComp.Name + '\".'  ) ;
				p.pse__Region__c.addError( errorMsg );
			}
		} 
	} // End of checkProjectCompany

}