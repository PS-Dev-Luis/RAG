public with sharing class PeriodHelper 
{

	
	private static List<c2g__codaPeriod__c> companyPeriods;
	private static final String OPENING_PERIOD = 	'000';
	private static final String ADJUSTMENT_PERIOD = '100';
	private static final String CLOSING_PERIOD = 	'101';	
	private static set<string> invalidPeriods = new set<String> { OPENING_PERIOD, ADJUSTMENT_PERIOD, CLOSING_PERIOD};

	public static Id getOpenPeriodIdForDate( Date periodDate )
	{
		c2g__codaCompany__c company = FFUtil.getCurrentCompany();
		c2g__codaPeriod__c nextOpenPeriod;
		
		
		for(c2g__codaPeriod__c queryPeriod : FFUtil.getPeriods())
		{
			if( isPeriodValid( queryPeriod ) )
			{
				if( isDateInPeriod( periodDate, queryPeriod ) )
				{
				   	return queryPeriod.Id;
				}   
				else if( isPeriodAfterDate( periodDate, queryPeriod ) )
				{
				   nextOpenPeriod = earliestPeriod( queryPeriod, nextOpenPeriod);   	
				}
			}	
		}
		return (nextOpenPeriod != null ? nextOpenPeriod.id : null );
	} 
	
	/**
	 *	Is Date In Period
	 *	-----------------
	 *	Rerturns true if supplied date falls in the Period. 
	 **/	
 	public static boolean isDateInPeriod( Date testDate, c2g__codaPeriod__c queryPeriod )
	{
		return( queryPeriod.c2g__StartDate__c <= testDate 
				&&
			    queryPeriod.c2g__EndDate__c >= testDate );
	}

	/**
	 *	Is Period After Date
	 *	--------------------
	 *	Returns true is Period is after supplied date (as determined by start date of the period).
	 **/	
	public static boolean isPeriodAfterDate( Date testDate, c2g__codaPeriod__c queryPeriod )
	{
		return( queryPeriod.c2g__StartDate__c >= testDate );
	}


	/**
	 *	Is Period Valid
	 *	---------------
	 *	Test to see if Period is Open and not Opening/closing/adjusting period.
	 **/
	public static boolean isPeriodValid(  c2g__codaPeriod__c queryPeriod )
	{
		return( invalidPeriods.contains(queryPeriod.c2g__PeriodNumber__c) == false 
			    && 
			    queryPeriod.c2g__Closed__c == false);
	}

	/**
	 *	earliest Period
	 *	---------------
	 *	Returns the earliest period of the two supplied periods.
	 **/
	public static c2g__codaPeriod__c earliestPeriod( c2g__codaPeriod__c queryPeriod1, c2g__codaPeriod__c queryPeriod2 )
	{
		if( queryPeriod1 == null || queryPeriod2 == null )
		{
			return ( queryPeriod1 != null ? queryPeriod1 : queryPeriod2 );
		}
		else
		{
			return( queryPeriod1.c2g__StartDate__c <= queryPeriod2.c2g__StartDate__c ? queryPeriod1 : queryPeriod2 );
		}
		
	}
	
	
}