/**
*   WipReportGenerator
*   =====================
*   Class to  generate WIP reports objects from Projects.  Used by
*   WipReport VF page.    
*
*   Luis Valenzuela 28/03/2013
*  
*	[LV20150603] Updated WIP report to allow for period filter as well as date filter.
*/
public with sharing class WipReportGenerator 
{
    // Uses inner class to wrap transaction extension value
    private map<String, GlValueDTO > glValues;
    
    private boolean isGLset = false;    
    private boolean usePeriodFilter = false;    
    private list <c2g__codaTransactionLineItem__c> lineItems;
    
    /********************************************************************************
     *  generateWipReport : Main method that generates the WIP report for a specific
     *                      project dependant on artefacts created upto a specified 
     *                      date.
     */    
    public WipReport__c generateWipReport( pse__proj__c project, date upToDate, WipReport__c wipReport )
    {
		return generateWipReport( project, upToDate, wipReport, RefData.WIP_REPORT_FILTER_TYPE_DATE ); 
    }
    
    public WipReport__c generateWipReport( pse__proj__c project, date upToDate, WipReport__c wipReport, String filterType )
    {
    	// New functionality added to allow periods to be used to filter transactions and timecards rather than a specific date.
    	usePeriodFilter = (filterType == refData.WIP_REPORT_FILTER_TYPE_PERIOD);
       
        upToDate = upToDate; // When used to retrieve data .addDays(1) added for inclusive
        map<String, String> lclRptToGlMap = GlSettings.rptToGlMap;
        // add necessary fields to project
        project = enrichProject(project);

        if(usePeriodFilter)
        {
        	c2g__codaPeriod__c snapShotPeriod;
        	// set up to date for time cards to be last date of the period.
        	for( c2g__codaPeriod__c period : FFUtil.getPeriods() )
        	{
        		if( period.id == wipReport.snapShotPeriod__c )
        		{
        			snapShotPeriod = period;
        			upToDate = period.c2g__EndDate__c;
        		}
        	}
        	getGlValues(project, lclRptToGlMap.keySet(), snapShotPeriod );
        }
        else
        {	
        	getGlValues(project, lclRptToGlMap.keySet() , upToDate);
        }

        String projCurr = project.CurrencyIsoCode;
        Log.debug(' WIP Generator Project');

        // build temp timeSheet Totals
        TimeSheetDTO tempActTimesheetTotals = calculateActualTimeSheets( project, upToDate );
        /* Create new WIP object to replace existing. */
        wipReport = new WipReport__c(   
            
            Id                                      = wipReport.id, 
            CurrencyIsoCode                         = project.CurrencyIsoCode,
            name                                    = 'WIP Report - ' + ' ' 
                                                        + ( null != project.Project_Code__c ? project.Project_Code__c : '' )  
                                                            + ' ' + date.today().format(),
            Project__c                              = project.id,
            snapShotDate__c                         = upToDate,
            snapShotPeriod__c  						= wipreport.snapShotPeriod__c,
            filterType__c                         	= filterType,
            
            // Budget section brought from Project fields propagated from Opportunity, coverted to Home currency
            budgetInternalLabourCost__c             = project.Internal_Labour_Cost__c,
            budgetCalcInternalLabourCharge__c       = project.Calculated_Internal_Labour_Cost2__c,
            budgetSubLabourCost__c                  = project.Subcontractor_Labour_Cost_2__c,
            budgetCalcSubLabourCharge__c            = project.Calculated_Subcontractor_Labour_Cost__c,
            budgetSubExpenses__c                    = project.Subcontractor_Expenses__c,
            budgetOopeChargePercent__c              = project.OOPE_Charge_Applied__c,
            budgetCalcOopeCharge__c                 = project.Calculated_OOPE_Charge_Applied__c,
            budgetAdminChargePercent__c             = project.Admin_Charge_Applied__c,
            budgetCalcAdminCharge__c                = project.Calculated_Admin_Charge_Applied__c,
            budgetDbChargePercent__c                = project.Database_Charge_Applied__c,   
            budgetCalcDbCharge__c                   = project.Calculated_Database_Charge_Applied__c,
            budgetPassedThroughCost__c              = project.Pass_Through_Costs2__c,
            budgetProfFees__c                       = project.Project_Value__c,
            
            // Actual section populated by existing approved Project artefacts 
            actualInternalLabourCost__c             = getGLvalue( GlSettings.actualIntLabRepCode ).value,
            actualCalcInternalLabourCharge__c       = getGLvalue( GlSettings.actualIntLabRepCode ).extension,
            actualSubLabourCost__c                  = getGLvalue( GlSettings.actualSubFeeRepCode ).value,
            actualCalcSubLabourCharge__c            = getGLvalue( GlSettings.actualSubFeeRepCode ).extension,
            actualSubExpenses__c                    = getGLvalue( GlSettings.actualSubExpRepCode ).value,
            actualCalcOopeCharge__c                 = getGLvalue( GlSettings.actualExpRepCode ).value,
            actualCalcAdminCharge__c                = calculateActualAdminCharge( project ),                                 
            actualCalcDbCharge__c                   = calculateActualDbCharge( project ),                                        
            actualPassedThroughCost__c              = getGLvalue( GlSettings.actualPassThruRepCode ).value,
            actualUnathorisedLabourCost__c          = tempActTimesheetTotals.costValue, // Unauthorised timesheets costs
            actualUnathorisedLabourCharge__c        = tempActTimesheetTotals.billValue, // Unauthorised timesheets charges
            
            // Billed section populated by Invoiced data
            billedProfFeesCharge__c                 = -getGLvalue( GlSettings.billedProfFeeRepCode ).value,
            billedMilestoneProfFeesCharge__c        = -getGLvalue( GlSettings.billedMsProfFeeRepCode ).value,
            billedMileStoneAdminCharge__c           = -getGLvalue( GlSettings.billedMsAdminRepCode ).value,
            billedMilestoneDbCharge__c              = -getGLvalue( GlSettings.billedMsDbRepCode ).value,
            billedMiscAdjsCharge__c                 = -getGLvalue( GlSettings.billedMiscAdjRepCode ).value,
            billedExpenses__c                       = -getGLvalue( GlSettings.billedExpRepCode ).value,
            billedPassedThroughCost__c              = -getGLvalue( GlSettings.billedPassThruRepCode ).value,
            billedDeferredRev__c                    = -getGLvalue( GlSettings.billedDeferRevRepCode ).value,
            
            // Cost 2 Date Section populated by non invoiced Bill events
            cost2DateInternalLabourCost__c          = getGLvalue( GlSettings.authIntLabRepCode ).value,
            cost2DateCalcInternalLabourCharge__c    = getGLvalue( GlSettings.authIntLabRepCode ).extension,
            cost2DateSubLabourCost__c               = getGLvalue( GlSettings.authSubFeeRepCode ).value,
            cost2DateCalcSubLabourCharge__c         = getGLvalue( GlSettings.authSubFeeRepCode ).extension,
            cost2DateSubExpenses__c                 = getGLvalue( GlSettings.authSubExpRepCode ).value,
            cost2DateCalcOopeCharge__c              = getGLvalue( GlSettings.authExpRepCode ).value,
            cost2DateCalcAdminCharge__c             = calculateCost2DateAdminCharge( project ), 
            cost2DateCalcDbCharge__c                = calculateCost2DateDbCharge( project), 
            cost2DatePassedThroughCost__c           = getGLvalue( GlSettings.authPassThruRepCode ).value,
            cost2DateSubFeeNotRec__c                = getGLvalue( GlSettings.authSubFeeInvNotRecRepCode ).value,
            cost2DateSubExpNotRec__c                = getGLvalue( GlSettings.authSubExpInvNotRecRepCode ).value,
            cost2DatePassthruNotRec__c              = getGLvalue( GlSettings.authPassThruNotRecRepCode ).value,

            status__c                               = refData.WIP_STATUS_GEN , 
        	Timestamp__c							= DateTime.now()					
        );

        // Budget totals         
        wipReport.budgetTotCosts__c                 = calculateBudgetTotCosts( wipReport );               
        wipReport.budgetTotCharge__c                = calculateBudgetTotCharges( wipReport );              
        wipReport.budgetExpenses__c                 = calculateBudgetExps( wipReport, project ); 
        wipReport.budgetTotalFee__c                 = wipreport.budgetProfFees__c + wipreport.budgetExpenses__c; 
        // Defend against / 0 when calculating the %
        wipReport.budgetRecRate__c                  = ( wipReport.budgetTotCharge__c != 0.0 ?
                                                        (wipReport.budgetTotalFee__c / wipReport.budgetTotCharge__c) * 100 
                                                            : -1 ).setScale(1);    
        // Actual Totals
        wipReport.actualCostSubtotal__c             = calculateActSubTotCosts( wipReport );  
        wipReport.actualChargeSubtotal__c           = calculateActSubTotCharges( wipReport );   
        wipReport.actualCostTotal__c                = wipReport.actualCostSubtotal__c + wipReport.actualUnathorisedLabourCost__c;    
        wipReport.actualChargeTotal__c              = wipReport.actualChargeSubtotal__c + wipReport.actualUnathorisedLabourCharge__c;   
        // Billed Total
        wipReport.billedTotal__c                    = calculateBilledTotCharges( wipReport );      
        // Cost 2 date Total
        wipReport.cost2DateCostTotal__c             = calculateCost2DateTotCosts( wipReport );
        wipReport.cost2DateChargeTotal__c           = calculateCost2DateTotCharges( wipReport );
        // Calculate KPIs                                                                   
        wipReport.kpiActualCostsOnBudget__c         = calculateKpiActualCostsOnBudget(wipReport);
        wipReport.kpiActualRecRate__c               = calculateKpiActualRecRate(wipReport); 
        wipReport.kpiGrossProfit__c                 = calculatekpiGrossProfit(wipReport);
        wipReport.kpiContribution__c                = calculateKpiContribution( WipReport); 
        
        try
        {
            Log.debug(wipReport);
            upsert wipReport;
        }
        catch( Dmlexception e )
        {
            Log.warn( 'Failed to create WIP report for Project - ' + Project.Project_Code__c + '\n' + e.getMessage());
            wipReport.addError('Failed to generate WIP report.  Error: ' + e.getMessage());
        }
        
        return wipReport; 
    } // end of generateWipReport
    
    
    /***********************************
     * Calculation Methods for totals  *
     ***********************************/ 
            
    /* Budget Total Costs */
    private decimal calculateBudgetTotCosts( WipReport__c wipRep) 
    {
        return ( nonNull( wipRep.budgetInternalLabourCost__c)
                    + nonNull( wipRep.budgetSubLabourCost__c )
                        + nonNull( wipRep.budgetSubExpenses__c )
                            + nonNull( wipRep.budgetPassedThroughCost__c ) ).setScale(2);
    }
    /* Budget Total Charge */
    private  decimal calculateBudgetTotCharges( WipReport__c wipRep )  
    {
        return ( nonNull( wipRep.budgetCalcInternalLabourCharge__c ) 
                    + nonNull( wipRep.budgetCalcSubLabourCharge__c ) 
                        + nonNull( wipRep.budgetSubExpenses__c ) 
                            + nonNull( wipRep.budgetCalcOopeCharge__c ) 
                                + nonNull( wipRep.budgetCalcAdminCharge__c ) 
                                    + nonNull( wipRep.budgetCalcDbCharge__c ) 
                                        + nonNull( wipRep.budgetPassedThroughCost__c ) ).setScale(2);
    }

    /* Budget Total Expenses */
    private  decimal calculateBudgetExps( WipReport__c wipRep,  pse__proj__c proj ) 
    { 
        return ( nonNull( wipRep.budgetSubExpenses__c ) 
                    + ( (nonNull(proj.OOPE_Charge_Applied__c) / 100) * wipRep.budgetProfFees__c ) 
                        + ( (nonNull(proj.Admin_Charge_Applied__c) / 100) * wipRep.budgetProfFees__c ) 
                            + ( (nonNull(proj.Database_Charge_Applied__c) / 100) * wipRep.budgetProfFees__c ) 
                                + nonNull( wipRep.budgetPassedThroughCost__c ) ).setScale(2);
    }
  
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /* Actual Timesheets Calc */
    private  TimeSheetDTO calculateActualTimeSheets( pse__proj__c proj, date upToDate )                          
    {
        list<pse__Timecard__c> timeCards = [ Select Id,
                                                    CurrencyIsoCode,
                                                    pse__Total_Cost__c, 
                                                    pse__Total_Billable_Amount__c 
                                              From  pse__Timecard__c
                                             Where  pse__Project__c = :proj.Id 
                                                and pse__Start_Date__c < :upToDate.addDays(1)
                                                and pse__Status__c = :refData.TIMECARD_STATUS_SUBMITTED ]; 
        TimeSheetDTO retTotals = new TimeSheetDTO(0.0, 0.0);
 
        for(pse__Timecard__c tc : timeCards)
        {
            retTotals.costValue += CurrencyHelper.convertFromTo( tc.pse__Total_Cost__c , tc.CurrencyIsoCode, proj.CurrencyIsoCode);
            retTotals.billValue += CurrencyHelper.convertFromTo( tc.pse__Total_Billable_Amount__c , tc.CurrencyIsoCode, proj.CurrencyIsoCode);
        }
        return retTotals;
    }   
    /* Actual Admin Charge */
    private  decimal calculateActualAdminCharge( pse__proj__c proj)
    {
        // (Internal Lab + Sub fees) * Admin %
        return ( (  getGLvalue( GlSettings.actualIntLabRepCode ).extension 
                        +  getGLvalue( GlSettings.actualSubFeeRepCode ).extension ) 
                            * (nonNull( proj.Admin_Charge_Applied__c) / 100 ) ).setScale(2) ; 
    }
    /* Actual Db Charge */
    private  decimal calculateActualDbCharge( pse__proj__c proj ) 
    {
        // (Internal Lab + Sub fees) * Db %
        return ( (  getGLvalue( GlSettings.actualIntLabRepCode ).extension 
                        +  getGLvalue( GlSettings.actualSubFeeRepCode ).extension ) 
                            * (nonNull( proj.Database_Charge_Applied__c) /100 ) ).setScale(2) ; 
    }
    /* Actual SubTotal Costs */
    private  decimal calculateActSubTotCosts( WipReport__c wipRep )                          
    {
        return ( wipRep.actualInternalLabourCost__c
                    + wipRep.actualSubLabourCost__c
                        + wipRep.actualSubExpenses__c
                            + wipRep.actualCalcOopeCharge__c
                                + wipRep.actualPassedThroughCost__c ).setScale(2);
    }
    /* Actual SubTotal Charges */
    private  decimal calculateActSubTotCharges( WipReport__c wipRep )                          
    {
        return ( wipRep.actualCalcInternalLabourCharge__c
                    + wipRep.actualCalcSubLabourCharge__c
                        + wipRep.actualSubExpenses__c
                            + wipRep.actualCalcOopeCharge__c
                                + wipRep.actualCalcAdminCharge__c
                                    + wipRep.actualCalcDbCharge__c
                                        + wipRep.actualPassedThroughCost__c ).setScale(2);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /* Billed Total Charge */
    private  decimal calculateBilledTotCharges( WipReport__c wipRep ) 
    {
        return ( wipRep.billedProfFeesCharge__c
                    + wipRep.billedMilestoneProfFeesCharge__c
                        + wipRep.billedMileStoneAdminCharge__c
                            + wipRep.billedMilestoneDbCharge__c
                                + wipRep.billedMiscAdjsCharge__c
                                    + wipRep.billedExpenses__c
                                        + wipRep.billedPassedThroughCost__c ).setScale(2);    
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /* Cost2Date (Auth) Admin Charge */
    private  decimal calculateCost2DateAdminCharge( pse__proj__c proj ) 
    {
        // (Internal Lab + Sub fees) * Admin %
        return ( ( getGLvalue( GlSettings.authIntLabRepCode ).extension 
                        + getGLvalue( GlSettings.authSubFeeRepCode).extension )
                            *  (nonNull(proj.Admin_Charge_Applied__c)/100) ).setScale(2); 
    }
    /* Cost2Date (Auth) Db Charge */
    private  decimal calculateCost2DateDbCharge( pse__proj__c proj ) 
    {
        // (Internal Lab + Sub fees) * Db %
        return ( ( getGLvalue( GlSettings.authIntLabRepCode ).extension 
                        + getGLvalue( GlSettings.authSubFeeRepCode).extension )
                            * (nonNull( proj.Database_Charge_Applied__c)/100 ) ).setScale(2); 
    }
    /* Cost2Date (Auth) Total Costs */
    private  decimal calculateCost2DateTotCosts( WipReport__c wipRep )                            
    {
        return ( wipRep.cost2DateInternalLabourCost__c
                    + wipRep.cost2DateSubLabourCost__c
                        + wipRep.cost2DateSubExpenses__c
                            + wipRep.cost2DateCalcOopeCharge__c
                                + wipRep.cost2DatePassedThroughCost__c ).setScale(2);
    }
    /* Cost2Date (Auth) Total Charge */
    private  decimal calculateCost2DateTotCharges( WipReport__c wipRep )                            
    {
        return ( wipRep.cost2DateCalcInternalLabourCharge__c
                    + wipRep.cost2DateCalcSubLabourCharge__c
                        + wipRep.cost2DateSubExpenses__c
                            + wipRep.cost2DateCalcOopeCharge__c
                                + wipRep.cost2DateCalcAdminCharge__c
                                    + wipRep.cost2DateCalcDbCharge__c
                                        + wipRep.cost2DatePassedThroughCost__c ).setScale(2);
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    /* KPI - Actual Costs on Budget */
    private decimal calculateKpiActualCostsOnBudget( WipReport__c wipRep )                          
    {
        return ( wipRep.budgetTotCosts__c != 0.0 ?
                    (wipRep.cost2DateCostTotal__c / wipRep.budgetTotCosts__c) * 100 
                        : -1 ).setScale(1);
    }
    /* KPI - Actual Recovery Rate */
    private decimal calculateKpiActualRecRate( WipReport__c wipRep )                          
    {
        return  ( wipRep.cost2DateChargeTotal__c != 0.0 ?
                    ( wipRep.billedTotal__c / wipRep.cost2DateChargeTotal__c ) * 100 
                        : -1 ).setScale(1);
    }
    /* KPI - Gross Profit */
    private decimal calculatekpiGrossProfit( WipReport__c wipRep )                          
    {
        return  ( wipRep.billedTotal__c - wipRep.billedPassedThroughCost__c != 0.0 ?
                    ( ( wipRep.billedTotal__c 
                        -  wipRep.cost2DateSubLabourCost__c
                            - wipRep.cost2DateSubExpenses__c
                            	- wipRep.cost2DateCalcOopeCharge__c 
                            		- wipRep.cost2DatePassedThroughCost__c)
                                    	/ ( wipRep.billedTotal__c - wipRep.billedPassedThroughCost__c ) ) * 100 
                        : -1 ).setScale(1);
    }
    /* KPI - Contributiion */
    private decimal calculateKpiContribution( WipReport__c wipRep )                          
    {
        return  ( wipRep.billedTotal__c - wipRep.billedPassedThroughCost__c != 0.0 ?
                    ( ( wipRep.billedTotal__c - wipRep.cost2DateCostTotal__c )
                        / ( wipRep.billedTotal__c - wipRep.billedPassedThroughCost__c ) ) * 100 
                            : -1 ).setScale(1);
    }
    
    /********************
     * Utility Methods  *
     ********************/ 
    // Method to populate required fields for Project
    private pse__proj__c enrichProject( pse__proj__c proj)
    {
        return [select  id,
                        CurrencyIsoCode,
                        Internal_Labour_Cost__c,
                        Calculated_Internal_Labour_Cost2__c,
                        Subcontractor_Labour_Cost_2__c,
                        Calculated_Subcontractor_Labour_Cost__c,
                        Subcontractor_Expenses__c,
                        OOPE_Charge_Applied__c,
                        Calculated_OOPE_Charge_Applied__c,
                        Admin_Charge_Applied__c,
                        Calculated_Admin_Charge_Applied__c,
                        Database_Charge_Applied__c, 
                        Calculated_Database_Charge_Applied__c,
                        Pass_Through_Costs2__c,
                        Project_Value__c,
                        Project_Code__c
                   from pse__proj__c
                  where id = :proj.id];
    }

    // Methods to return all transaction lines for a specific project from a specific GL account upto a specified date
    public map<String, GlValueDTO> getGlValues( pse__proj__c project, Set<String> repCodes, date upToDate)
    {
		return getGlValues( project, repCodes, upToDate, null );
    }
    public map<String, GlValueDTO> getGlValues( pse__proj__c project, Set<String> repCodes, c2g__codaPeriod__c snapShotPeriod )
    {
		return getGlValues( project, repCodes, null, snapShotPeriod );
    }
    
    public map<String, GlValueDTO> getGlValues( pse__proj__c project, Set<String> repCodes, date upToDate, c2g__codaPeriod__c snapShotPeriod )
    {
        if( isGLset == false )
        {
            glValues = new map<String, GlValueDTO>();
            getLineItems( project, repCodes, upToDate, snapShotPeriod );
            GlValueDTO gl;
            String RepCode;                                                        
          
            String actExpenseGlWildCard = GlSettings.actualExpRepCode;
            String authExpenseGlWildCard = GlSettings.authExpRepCode;
              
            // Aggregate totals for GL accounts from all transaction lines including additional transaction extension 
            for( c2g__codaTransactionLineItem__c linItm : lineItems)
            {
                repCode = linItm.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c;
                // If repcode is within actual expense range currently 6307*
                if( repCode.startsWith( actExpenseGlWildCard.substringBefore('*') )) 
                {
                    gl = getGLvalue( GlSettings.actualExpRepCode );
                    // Convert all transaction values to Project currency
                    gl.value = gl.value + CurrencyHelper.convertFromTo( nonNull( linItm.c2g__HomeValue__c ), 
                               												linItm.c2g__HomeCurrency__r.Name, 
                               													project.CurrencyIsoCode);
                    
                    gl.extension = gl.extension + CurrencyHelper.convertFromTo( nonNull( linItm.calculated_charge2__c), 
                               														linItm.c2g__HomeCurrency__r.Name, 
							                                        					project.CurrencyIsoCode) ;
                    glValues.put( GlSettings.actualExpRepCode , gl );
                }
                // If repcode is within authorised expense range currently 22*
                else if( repCode.startsWith( authExpenseGlWildCard.substringBefore('*') ))
                {
                    gl = getGLvalue( GlSettings.authExpRepCode );
                    // Convert all transaction values to Project currency
                    gl.value = gl.value + CurrencyHelper.convertFromTo( nonNull( linItm.c2g__HomeValue__c ), 
                               														linItm.c2g__HomeCurrency__r.Name, 
                    																	project.CurrencyIsoCode);
        
                    gl.extension = gl.extension + CurrencyHelper.convertFromTo( nonNull( linItm.calculated_charge2__c), 
		                               														linItm.c2g__HomeCurrency__r.Name, 
                    																			project.CurrencyIsoCode) ;
                    glValues.put( GlSettings.authExpRepCode , gl );
                }
                else
                {
                    gl = getGLvalue( repCode );
                    // Convert all transaction values to Project currency
                    gl.value = gl.value + CurrencyHelper.convertFromTo( nonNull( linItm.c2g__HomeValue__c ), 
                               														linItm.c2g__HomeCurrency__r.Name, 
                    																	project.CurrencyIsoCode);
                   
                    gl.extension = gl.extension + CurrencyHelper.convertFromTo( nonNull( linItm.calculated_charge2__c), 
		                               														linItm.c2g__HomeCurrency__r.Name, 
																			                    project.CurrencyIsoCode) ;
                    glValues.put( repCode , gl );
                }
            }
            Log.Debug(glValues);
            isGLset = true;
        }
        return glValues;
    }
    
    public list <c2g__codaTransactionLineItem__c> getLineItems( pse__proj__c project, Set<String> repCodes, date upToDate, c2g__codaPeriod__c snapShotPeriod )
    {
        // Special condition as Expenses run over multiple GL codes so aggreagate all 22* GL codes, first replace * with
        // % necessary for SOQL like query
        String actExpenseGlWildCard = GlSettings.actualExpRepCode.replace('*', '%');
        String authExpenseWildCard = GlSettings.authExpRepCode.replace('*', '%');
        
        date filterDate;
        if( usePeriodFilter )
       	{
        	filterDate = snapShotPeriod != null ? snapShotPeriod.c2g__endDate__c.addDays(1) : null;
       	} 
       	else
       	{
        	filterDate = upToDate.addDays(1);
       	}
        id projId = project.Id;
        
        if( lineItems == null )
        {
            String query = ' Select Id,																						'+
                           '   	 	c2g__HomeValue__c, 																		'+
	                       '        calculated_charge2__c,																	'+
	                       '        c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,										'+
	                       '        c2g__HomeCurrency__r.Name																'+
	                       '    From 																						'+
	                       '		c2g__codaTransactionLineItem__c 														'+
	                       '  where c2g__Dimension3__r.Project__c = :projId		 											';
			if( usePeriodFilter )
			{                    
	        	query +=   ' 	AND c2g__Transaction__r.c2g__Period__r.c2g__endDate__c < :filterDate	';
			}
			else
			{
	        	query +=   ' 	AND c2g__Transaction__r.c2g__TransactionDate__c < :filterDate';
			}
	        query +=       '    AND ( c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c in :repCodes 						'+
	                       '            OR																					'+
	                       '          c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c like :actExpenseGlWildCard			'+
	                       '            OR																					'+
	                       '          c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c like :authExpenseWildCard )	  	';+
        
        	lineItems = Database.query(query);
        }
        Log.Debug(lineItems);
        return lineItems;
    }
    
    
    // Defensive methods to return 0.0 if GL account not setup or no entries exist
    private GlValueDTO getGLvalue(String RepCode)
    {
        return (  glValues.get( RepCode ) != null ?  glValues.get( RepCode ) : new GlValueDTO(0.0, 0.0) ) ;
    }
    private decimal nonNull(decimal value)
    {
        return ( value != null ? value : 0.0 );     
    }
    
 
    /**********************
     * Inner Classes DTOs *
     **********************/
    // Internal class to hold dual values from transaction lines
    private class GlValueDTO 
    {
        public Decimal value{get; set;}
        public Decimal extension{get; set;}
    
        public GlValueDTO( decimal val, decimal ext ) 
        {
            this.value = val;
            this.extension = ext;
        }
    }
    
    // Internal class to hold dual values from transaction lines
    private class TimeSheetDTO 
    {
        public Decimal costValue{get; set;}
        public Decimal billValue{get; set;}
    
        public TimeSheetDTO( decimal cst, decimal bil ) 
        {
            this.costValue = cst;
            this.billValue = bil;
        }
    }
}