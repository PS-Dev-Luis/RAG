/**
*	JournalCreationHelper
*	======================
*	Helper class that builds appropriate Journal and lines associated with a
*	Project and timecard approval event.
*
*	Luis Valenzuela 05/03/2013
*
*/
public with sharing class JournalCreationHelper 
{
	private static Id subFeeCredGL = CustomSettings.subContractorFeeCreditGLid;
	private static Id subFeeDebGL = CustomSettings.subContractorFeeDebitGLid;

	private static Id subExpCredGL = CustomSettings.subContractorExpenseCreditGLid;
	private static Id subExpDebGL = CustomSettings.subContractorExpenseDebitGLid;

	private static Id passThruCredGL = CustomSettings.passThroughCostsCreditGLid;
	private static Id passThruDebGL = CustomSettings.passThroughCostsDebitGLid;

	private static Id timecardCredGL = CustomSettings.timecardCreditGLid;
	private static Id timecardDebGL = CustomSettings.timecardDebitGLid;
	
	// Variables used for holding the Dimension Maps
	// Dim 1 Practice
	private static map<String, id> practiceDimMap = new map<String, id>();
	// Dim 2 Group
	private static map<String, id> groupDimMap = new map<String, id>();
	// Dim 3 Project
	private static map<id, pse__Proj__c> projDimMap = new map<id, pse__Proj__c>();
	// Dim 4 Employee
	private static map<String, id> employeeDimMap = new map<String, id>();
	private static map<id,pse__Timecard_Header__c> tC2employeeCodeMap = new map<id, pse__Timecard_Header__c>();
	
	/**
	 * createJournal ( Projects )
	 * ===========================
	 * Generate Journal and lines for sub fee, sub exp and pass through when Project
	 * is approved. Called from ProjectTrigger 
	 */
	public static void createJournal( list<pse__Proj__c> projects )
	{
		map<Id, c2g__codaJournal__c> newJournals = new map<Id, c2g__codaJournal__c>();
		
		// Build currency map
		set<String> currencyIsoCodes = new set<String>();
		for ( pse__Proj__c proj : projects )
		{
			currencyIsoCodes.add(proj.CurrencyIsoCode);
			projDimMap.put(proj.id, null);
		}
		map<String,c2g__codaAccountingCurrency__c> accountingCurrencies = CurrencyHelper.getAccCurrencies(currencyIsoCodes);

		c2g__codaAccountingCurrency__c curr;
		// Create a Journal for each approved project

		// Build Dimension Reference data
		buildDims( projDimMap.keyset(), null );			
	
		integer lineCount;
		decimal currentSubFee = 0.0;
		decimal currentSubChrg = 0.0;
		decimal currentSubExp = 0.0;
		decimal currentPassThru = 0.0;
		decimal convertedChargeValue = 0.0;

		c2g__codaDimension3__c projDim = null;
		list<c2g__codaJournalLineItem__c> newJournalLines = new list<c2g__codaJournalLineItem__c>();

		// LINES : Create Journal lines for Subcontractor fees, exprenses and pass thru costs. 
		for ( pse__Proj__c proj : projects )
		{		
			// Safeguard
			curr = accountingCurrencies.get(proj.CurrencyIsoCode);
			if( curr == null )
			{
				proj.addError('Currency ' + proj.CurrencyIsoCode + ' not in accounting currencies, cannot create journals.');
				return;
			}
															 	
			if(proj.is_internal_project__c)
			{
				// Do not create journals for internal projects
				continue;
			}
			
			lineCount = 1;
			// Dim necessary for WIP report referencing 
			// Dim 1
			String practiceName = ( projDimMap.get(proj.id).pse__Practice__c != null ?  projDimMap.get(proj.id).pse__Practice__r.Name : null );
			// Dim 2
			String groupName = ( projDimMap.get(proj.id).pse__Group__c != null ? projDimMap.get(proj.id).pse__Group__r.Name : null );
			// Dim 3
			projDim = ( !projDimMap.get(proj.id).Dimension_3__r.isEmpty() ) ? projDimMap.get(proj.id).Dimension_3__r : null;
			 
			currentSubFee = proj.Subcontractor_Labour_Cost_2__c != null ? proj.Subcontractor_Labour_Cost_2__c : 0.0;
			currentSubChrg = proj.Calculated_Subcontractor_Labour_Cost__c != null ? proj.Calculated_Subcontractor_Labour_Cost__c : 0.0;
			if ( currentSubFee != 0.0 || currentSubChrg != 0.0 )
			{
				convertedChargeValue = CurrencyHelper.convertToHome(currentSubChrg, proj.CurrencyIsoCode );
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_CRED,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -currentSubFee.setscale(2),
																		calculated_charge2__c =	-convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = subFeeCredGL));
																		
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_DEBIT,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = currentSubFee.setscale(2),
																		calculated_charge2__c = convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = subFeeDebGL) );
		   	}// End of Subcontractor Fee
			
			// Subcontractor Expenses test
			currentSubExp = proj.Subcontractor_Expenses_2__c != null ? proj.Subcontractor_Expenses_2__c : 0.0;
			
			if ( currentSubExp != 0.0 )
		   	{	
				convertedChargeValue = CurrencyHelper.convertToHome( currentSubExp, proj.CurrencyIsoCode );
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_CRED,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -currentSubExp.setscale(2),
																		calculated_charge2__c =	-convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = subExpCredGL)); 

				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_DEBIT,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = currentSubExp.setscale(2),
																		calculated_charge2__c =	convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = subExpDebGL)); 
		   	} // End of Subcontractor Expenses 
		 
		 	// Pass through costs
		 	currentPassThru =  proj.Pass_Through_Costs2__c != null ? proj.Pass_Through_Costs2__c : 0.0;
			if ( currentPassThru != 0.0 )
		   	{	
				convertedChargeValue = CurrencyHelper.convertToHome( currentPassThru, proj.CurrencyIsoCode );
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_CRED,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -currentPassThru.setscale(2),
																		calculated_charge2__c =	-convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = passThruCredGL)); 
				
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_PASS_THRU_COSTS_DEBIT,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = currentPassThru.setscale(2),
																		calculated_charge2__c =	convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim != null ? projDim.Id : null),
																		ffpsai__Project__c = proj.Id,
																		c2g__LineNumber__c = (lineCount++),
																		c2g__GeneralLedgerAccount__c = passThruDebGL)); 
		   	} // End of Pass though costs
		   	
			// HEADER: If lines exist then build the Journal header
			if( lineCount > 1 )
			{	   	
	   			String journalRef = 'Generated Journal for Project - ' + 
										( proj.get( DynamicFieldRef.PROJ_PROJECT_CODE_FIELD ) != null ? 
											proj.get( DynamicFieldRef.PROJ_PROJECT_CODE_FIELD ) : '' ) ;
				String journalDesc = 'Project - ' + proj.Name + '(' + proj.id + ')';
			   	
				newJournals.put( proj.Id,  new c2g__codaJournal__c( CurrencyIsoCode = proj.CurrencyIsoCode,
																	c2g__JournalCurrency__c = (curr != null ? curr.id : null),
			  														c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
													 				c2g__JournalDate__c = Date.today(),
																 	c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
																 	c2g__Reference__c = journalRef,
																	c2g__JournalDescription__c = journalDesc,
																	ffgl__DeriveCurrency__c = false,
														 			ffgl__DerivePeriod__c = true));
			}
			
		} // end of for loop
		

		if( newJournalLines != null && newJournalLines.size() > 0 )
		{
			// Insert new Journals
			try
			{
				insert newJournals.values();
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal from approved project : ' + e.getMessage());
			}
			// Add header to lines
			for(c2g__codaJournalLineItem__c jrnLin :  newJournalLines)
			{
				jrnLin.c2g__Journal__c = newJournals.get( jrnLin.ffpsai__Project__c).Id;
			}		
			// Insert Journal lines		
			try
			{
				insert newJournalLines;
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal lines for approved project : ' + e.getMessage());
			}
			// Post journals and create transaction lines
			postJournals( NewJournals.values() );
		}
	}


	/**
	 * createJournal ( Timecards )
	 * ===========================
	 * Generate Journal and lines for timecard totals when timecard
	 * is approved. Called from TimecardTrigger 
	 */
	public static void createJournal( list<pse__Timecard_Header__c> timeCardHdrs )
	{
		map<Id, c2g__codaJournal__c> newJournals = new map<Id, c2g__codaJournal__c>();
		map<id, pse__Timecard_Header__c> tcHrdMap = new map<id, pse__Timecard_Header__c> (timeCardHdrs);
		set<id> tcHdrIds = tcHrdMap.keySet();
		
		// Build currency map
		set<String> currencyIsoCodes = new set<String>();		
		list<pse__Timecard__c> tCSplits = [	select	id,
													CurrencyIsoCode,
													pse__Cost_Rate_Currency_Code__c,
													pse__End_Date__c,
													pse__Total_Cost__c,
													pse__Project__c,
													pse__Project__r.id,
													pse__Project__r.is_internal_project__c,
													pse__Project__r.Name,
													pse__Project__r.Project_Code__c,
													pse__Timecard_Header__c,
													pse__Timecard_Header__r.is_internal_project__c,
													pse__Total_Billable_Amount__c
												from
													pse__Timecard__c
												where
													pse__Timecard_Header__c in :tcHdrIds];

		for ( pse__Timecard__c tc : tCSplits )
		{
			currencyIsoCodes.add(tc.CurrencyIsoCode);
			currencyIsoCodes.add(tc.pse__Cost_Rate_Currency_Code__c);
			projDimMap.put( tc.pse__Project__c, null);
		}
	
		c2g__codaAccountingCurrency__c curr;
		map<String,c2g__codaAccountingCurrency__c> accountingCurrencies = CurrencyHelper.getAccCurrencies(currencyIsoCodes);

		/* Journal Lines */		
		// Build Dimension Reference data
		buildDims( projDimMap.keyset(), tcHdrIds );			
		
		integer lineCount;
		decimal timeCardCharge = 0.0;
		decimal timeCardCost = 0.0;
		decimal convertedChargeValue = 0.0;
		list<c2g__codaJournalLineItem__c> newJournalLines = new list<c2g__codaJournalLineItem__c>();
	
		// LINES : Create Journal lines for timecards. 
		for ( pse__Timecard__c timecard : tCSplits )
		{		
			if( timecard.pse__Project__r.is_internal_project__c )
			{
				// Do not create journals for internal projects
				continue;
			}
			
			curr = accountingCurrencies.get( timecard.pse__Cost_Rate_Currency_Code__c );
			if( curr == null )
			{
				timecard.addError('Currency ' + timecard.pse__Cost_Rate_Currency_Code__c + ' not in accounting currencies, cannot create journals.');
				return;
			}
			
			id tcPeriodId = PeriodHelper.getOpenPeriodIdForDate(timecard.pse__End_Date__c);
			if( tcPeriodId == null )
			{
				throw new appException( 'Journal creation failed - Could not find open period for date : ' + timecard.pse__End_Date__c); 
			}
	
			timeCardCharge = 0.0;
			lineCount = 1;
			// Timecard value (Total cost supplied as text with currency e.g USD 100 )
			// timeCardCost = decimal.valueOf( timecard.pse__Total_Cost__c.remove( timecard.pse__Cost_Rate_Currency_Code__c).deleteWhitespace() )
			timeCardCost =  timecard.pse__Total_Cost__c ;
			timeCardCharge = timecard.pse__Total_Billable_Amount__c;
			
			// Dims necessary for WIP report referencing 
			// Dim 1
			String practiceName = ( projDimMap.get(timecard.pse__Project__c).pse__Practice__c != null ? 
										projDimMap.get(timecard.pse__Project__c).pse__Practice__r.Name : null );
			// Dim 2
			String groupName = ( projDimMap.get(timecard.pse__Project__c).pse__Group__c != null ? 
										projDimMap.get(timecard.pse__Project__c).pse__Group__r.Name : null );
			// Dim 3
			c2g__codaDimension3__c projDim = ( !projDimMap.get(timecard.pse__Project__c).Dimension_3__r.isEmpty() ) ?
												projDimMap.get(timecard.pse__Project__c).Dimension_3__r : null;
			// Dim 4
			String employeeCode = ( tC2employeeCodeMap.get( timecard.pse__Timecard_Header__r.id ).pse__Resource__r != null ) ?
										tC2employeeCodeMap.get( timecard.pse__Timecard_Header__r.id ).pse__Resource__r.EmployeeCode__c : null;								
			
			// Create Journal lines
			if ( timeCardCharge != 0.0 || timeCardCost != 0.0)
			{
				// Charge is held as currency field and therefore in Timecard currency
				convertedChargeValue = CurrencyHelper.convertToHome(timeCardCharge, timecard.CurrencyIsoCode );
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = employeeCode  + ' : ' +  RefData.JOURNAL_LINE_DESC_TIMECARD_CRED,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -timeCardCost.setscale(2),
																		calculated_charge2__c = -convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim!= null ? projDim.Id : null),
																		c2g__Dimension4__c = employeeDimMap.get(employeeCode ),
																		ffpsai__Project__c = timecard.pse__Project__c,
																		c2g__LineNumber__c = (lineCount++),
																		Timecard_Split__c = timecard.id, 
																		c2g__GeneralLedgerAccount__c = timecardCredGL));
																		
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = employeeCode + ' : ' + RefData.JOURNAL_LINE_DESC_TIMECARD_DEBIT,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = timeCardCost.setscale(2),
																		calculated_charge2__c = convertedChargeValue.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim!= null ? projDim.Id : null),
																		c2g__Dimension4__c = employeeDimMap.get(employeeCode ),
																		ffpsai__Project__c = timecard.pse__Project__c,
																		c2g__LineNumber__c = (lineCount++),
																		Timecard_Split__c = timecard.id, 
																		c2g__GeneralLedgerAccount__c = timecardDebGL) );

				// Create Journal Header
				String journalRef = 'Generated Timecard Journal [' + timecard.pse__Project__r.Project_Code__c + ']';
				String journaDesc = 'Project - ' + timecard.pse__Project__r.Name + '(' + timecard.pse__Project__r.id 
										+ ') / Timecard (' + timecard.id +')' ;
				newJournals.put( timecard.Id, new c2g__codaJournal__c( 	CurrencyIsoCode = timecard.pse__Cost_Rate_Currency_Code__c,
				  														c2g__JournalCurrency__c = (curr != null ? curr.Id : null),
				  														c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
																		c2g__JournalDate__c = timecard.pse__End_Date__c,
																		c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
																		c2g__Reference__c = journalRef,
																		c2g__JournalDescription__c = journaDesc,
																		c2g__Period__c = tcPeriodId,
																		ffgl__DeriveCurrency__c = false,
																		ffgl__DerivePeriod__c = false));
		   	}
		} // end of for loop
		
			
		if( newJournalLines != null && newJournalLines.size() > 0 )
		{
			// Insert new Journals
			try
			{
				insert newJournals.values();
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal from approved timecard : ' + e.getMessage());
			}
			// Add header to lines
			for(c2g__codaJournalLineItem__c jrnLin :  newJournalLines)
			{
				jrnLin.c2g__Journal__c = newJournals.get( jrnLin.Timecard_Split__c).Id;
			}		
			// Insert Journal lines		
			try
			{
				insert newJournalLines;
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal lines for approved timecard : ' + e.getMessage());
			}
			// Post journals and create transaction lines
			postJournals( NewJournals.values() );
		}
		
	}


	/**
	 * createJournal ( Misc Adjs )
	 * ===========================
	 * Generate Journal and lines for Misc Adjs when
	 * is approved. Called from MiscAdjTrigger 
	 */
	public static void createJournal( list<pse__Miscellaneous_Adjustment__c> miscAdjs )
	{
		map<Id, c2g__codaJournal__c> newJournals = new map<Id, c2g__codaJournal__c>();
		map<id, pse__Miscellaneous_Adjustment__c> miscAdjMap = new map<id, pse__Miscellaneous_Adjustment__c> (miscAdjs);
		set<id> miscAdjsIds = miscAdjMap.keySet();
		
		// Build currency map
		set<String> currencyIsoCodes = new set<String>();		

		for ( pse__Miscellaneous_Adjustment__c ma : miscAdjs )
		{
			currencyIsoCodes.add(ma.CurrencyIsoCode);
			projDimMap.put( ma.pse__Project__c, null);
		}
	
		c2g__codaAccountingCurrency__c curr;
		map<String,c2g__codaAccountingCurrency__c> accountingCurrencies = CurrencyHelper.getAccCurrencies(currencyIsoCodes);

		/* Journal Lines */		
		// Build Dimension Reference data
		buildDims( projDimMap.keyset(), null );			
		
		integer lineCount;
		decimal miscAdjVal = 0.0;
		decimal convertedVal = 0.0;
		list<c2g__codaJournalLineItem__c> newJournalLines = new list<c2g__codaJournalLineItem__c>();
	
		// LINES : Create Journal lines for Misc Adjustments. 
		for ( pse__Miscellaneous_Adjustment__c miscAdj : miscAdjs )
		{		
			pse__Proj__c proj = projDimMap.get(miscAdj.pse__Project__c);
			
			if( proj.is_internal_project__c )
			{
				// Do not create journals for internal projects
				continue;
			}
			
			curr = accountingCurrencies.get( miscAdj.CurrencyIsoCode );
			if( curr == null )
			{
				miscAdj.addError('Currency ' + miscAdj.CurrencyIsoCode + ' not in accounting currencies, cannot create journals.');
				return;
			}

			if( miscAdj.ffpsai__BalancingGLACode__c == null || miscAdj.ffpsai__MiscAdjGLACode__c == null)
			{
				throw new appException('Misc Adj (' + miscAdj.id + ') is missing GLA information.');
			}
				
			miscAdjVal= miscAdj.pse__Amount__c;
			lineCount = 1;
			
			// Dims necessary for WIP report referencing 
			// Dim 1
			String practiceName = ( proj.pse__Practice__c != null ? proj.pse__Practice__r.Name : null );
			// Dim 2
			String groupName = ( proj.pse__Group__c != null ? proj.pse__Group__r.Name : null );
			// Dim 3
			c2g__codaDimension3__c projDim = ( !proj.Dimension_3__r.isEmpty() ) ? proj.Dimension_3__r : null;
			
			// Create Journal lines
			if ( miscAdjVal != 0.0 )
			{
				// Charge is held as currency field and therefore in Timecard currency
				convertedVal = CurrencyHelper.convertToHome( miscAdjVal, miscAdj.CurrencyIsoCode );
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = miscAdj.Name  + ' : ' +  RefData.JOURNAL_LINE_DESC_MISCADJ_CRED,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = -miscAdjVal.setscale(2),
																		calculated_charge2__c = -convertedVal.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim!= null ? projDim.Id : null),
																		ffpsai__Project__c = miscAdj.pse__Project__c,
																		c2g__LineNumber__c = (lineCount++),
																		Miscellaneous_Adjustment__c = miscAdj.id, 
																		c2g__GeneralLedgerAccount__c = miscAdj.ffpsai__BalancingGLACode__c));
																		
				newJournalLines.add( new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = miscAdj.Name + ' : ' + RefData.JOURNAL_LINE_DESC_MISCADJ_DEBIT,
																		c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
																		c2g__Value__c = miscAdjVal.setscale(2),
																		calculated_charge2__c = convertedVal.setscale(2),
																		c2g__Dimension1__c = practiceDimMap.get(practiceName),
																		c2g__Dimension2__c = groupDimMap.get(groupName ),
																		c2g__Dimension3__c = (projDim!= null ? projDim.Id : null),
																		ffpsai__Project__c = miscAdj.pse__Project__c,
																		c2g__LineNumber__c = (lineCount++),
																		Miscellaneous_Adjustment__c = miscAdj.id, 
																		c2g__GeneralLedgerAccount__c = miscAdj.ffpsai__MiscAdjGLACode__c) );

				// Create Journal Header
				String journalRef = 'Generated Misc Adj Journal [' + proj.Project_Code__c + ']';
				String journaDesc = 'Project - ' + proj.Name + '(' + proj.id + ') / Misc Adj (' + miscAdj.id +')' ;
				newJournals.put( miscAdj.Id, new c2g__codaJournal__c( 	CurrencyIsoCode = miscAdj.CurrencyIsoCode,
				  														c2g__JournalCurrency__c = (curr != null ? curr.Id : null),
				  														c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
																		c2g__JournalDate__c = Date.today(),
																		c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
																		c2g__Reference__c = journalRef,
																		c2g__JournalDescription__c = journaDesc,
																		ffgl__DeriveCurrency__c = false,
																		ffgl__DerivePeriod__c = true));
		   	}
		} // end of for loop
		
			
		if( newJournalLines != null && newJournalLines.size() > 0 )
		{
			// Insert new Journals
			try
			{
				insert newJournals.values();
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal from approved Misc Adj : ' + e.getMessage());
			}
			// Add header to lines
			for(c2g__codaJournalLineItem__c jrnLin :  newJournalLines)
			{
				jrnLin.c2g__Journal__c = newJournals.get( jrnLin.Miscellaneous_Adjustment__c ).Id;
			}		
			// Insert Journal lines		
			try
			{
				insert newJournalLines;
			}
			catch( Dmlexception e )
			{
			 	throw new AppException( 'Failed to create Journal lines for approved Misc Adj : ' + e.getMessage());
			}
			// Post journals and create transaction lines
			postJournals( NewJournals.values() );
		}
		
	}



	/**
	 * Build Dims
	 * ===========================
	 * Utility method to populate dims
	 */
	public static void buildDims( set<id> projIds, set<id> tcHdrIds)
	{		
		// Build the Dimensions
		// Dim 1
		list<c2g__codaDimension1__c> practiceDimList = new list<c2g__codaDimension1__c>( [Select Id, Name From c2g__codaDimension1__c]);   
		for( c2g__codaDimension1__c dim : practiceDimList ) 
		{
			practiceDimMap.put( dim.Name , dim.Id );
		}   								  	
		// Dim 2
		list<c2g__codaDimension2__c> groupDimList = new list<c2g__codaDimension2__c> ( [Select Id, Name From c2g__codaDimension2__c]);       								  	
		for( c2g__codaDimension2__c dim : groupDimList ) 
		{
			groupDimMap.put( dim.Name , dim.Id );
		}
		// Dim 3 : Retrieve Dims assoicated with the Projects
		projDimMap = new map<id, pse__Proj__c>([ Select p.Id, 
													  	is_internal_project__c,
														Name,
														Project_Code__c,
									  					// Dim 1
				  										pse__Practice__c,
													  	pse__Practice__r.Name,
													  	// Dim 2
													  	pse__Group__c,
													  	pse__Group__r.Name,
													  	// Dim 3
													  	(Select Id From Dimension_3__r limit 1)
   												 From pse__Proj__c p
		      								  	where p.Id in :projIds]);

		// only build the employee dim for Timecards
		if( tcHdrIds == null) return;

		// Dim 4 : Employee Code
		tC2employeeCodeMap = new map<id,pse__Timecard_Header__c>( [Select 
																		id, 
																		pse__Resource__r.EmployeeCode__c
																	From 
																		pse__Timecard_Header__c 
																	where
																		id in :tcHdrIds ]);
																		
		for( pse__Timecard_Header__c tcHdr : tC2employeeCodeMap.values() )
		{
			employeeDimMap.put( tcHdr.pse__Resource__r.EmployeeCode__c , null );
		}	 													
		list<c2g__codaDimension4__c> employeeDimList = new list <c2g__codaDimension4__c>( [  select	
																									id,
																									name
																								from
																									c2g__codaDimension4__c
																								where
																									name in :employeeDimMap.keySet()]);
		for( c2g__codaDimension4__c dim : employeeDimList)
		{
			employeeDimMap.put( dim.name , dim.id);
		}
	}
	
	
	/**
	 * postJournals ( Journals )
	 * ===========================
	 * Utility method to post Journals and therefore create transaction lines
	 */
	public static void postJournals(list<c2g__codaJournal__c> journals)
	{
		System.Savepoint createInvoiceSavePoint = Database.setSavepoint();
		
		c2g.CODAAPICommon_6_0.Context context = new c2g.CODAAPICommon_6_0.Context();
        context.token = EncodingUtil.convertToHex( Crypto.generateDigest('SHA1',
	                		Blob.valueOf('0000000000000000C000000000000046' + UserInfo.getUserId() + 
	                			'PROBABLEMENTE EL MEJOR SOFTWARE DE CONTABILIDAD EN EL MUNDO')));
	    for ( c2g__codaJournal__c journal : journals )
	    {            			
			try
			{
				c2g.CODAAPIJournal_6_0.PostJournal( context, c2g.CODAAPICommon.getRef( journal.id, null ) );
				Log.Debug( 'JOURNAL POSTED ');
		    }	
			catch( exception e )
			{
				//throw new AppException(e.getMessage() + e.getStackTraceString());
			 	Database.rollback(createInvoiceSavePoint);
			 	Log.warn( 'Failed to post Journal :' + e.getMessage() );
			 	journal.addError('Failed to post Journal. Error: ' +  e.getMessage());
			}
		}
	}

}