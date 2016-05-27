/**
 *  CurrencyHelper
 *  ===================
 *  Helper class to deal with currency calculation outside of FFA. 
 *
 *  Luis Valenzuela 10/05/2013 
 *
 **/
public with sharing class CurrencyHelper 
{
    private static map<String, c2g__codaAccountingCurrency__c > accountingCurrencies;    
    private static map<ID, c2g__codaAccountingCurrency__c > accountingCurrenciesById;    
    
    
    /** 
     * Function to Convert value TO Home value using current rate
     **/
    // By currency ISO code
    public static decimal convertToHome( decimal value, String currencyIsoCode )
    {
       	testValue(value);
        try
        {    
            if( getAccCurrency(currencyIsoCode).get(currencyIsoCode).c2g__Home__c )
            {
                return value;
            }
            return (value / getAccCurrency(currencyIsoCode).get(currencyIsoCode).c2g__ExchangeRates__r[0].c2g__Rate__c).setScale(2) ;
        }
        catch( exception e ) { throw new AppException( handleError(e, currencyIsoCode) ); }
    }   
    // By Accounting Currency ID
    public static decimal convertToHome( decimal value, Id accCurrency )
    {
    	testValue(value);    	
        try
        {    
            if( getAccCurrency(accCurrency).get(accCurrency).c2g__Home__c )
            {
                return value;
            }
            return ( value / getAccCurrency(accCurrency).get(accCurrency).c2g__ExchangeRates__r[0].c2g__Rate__c).setScale(2) ;
        }
        catch( exception e ) { throw new AppException( handleError(e, accCurrency ) ); }
    }   



    /** 
     * Function to Convert value FROM Home value using current rate
     **/
    public static decimal convertFromHome( decimal value, String currencyIsoCode )
    {
       	testValue(value);
        try
        {    
            if( getAccCurrency(currencyIsoCode).get(currencyIsoCode).c2g__Home__c )
            {
                return value;
            }
            return (value * getAccCurrency(currencyIsoCode).get(currencyIsoCode).c2g__ExchangeRates__r[0].c2g__Rate__c).setScale(2) ;
        }
        catch( exception e ) { throw new AppException( handleError(e, currencyIsoCode) ); }
    }
    public static decimal convertFromHome( decimal value, Id accCurrency )
    {
       	testValue(value);
        try
        {     
            if( getAccCurrency(accCurrency).get(accCurrency).c2g__Home__c )
            {
                return value;
            }
            return (value * getAccCurrency(accCurrency).get(accCurrency).c2g__ExchangeRates__r[0].c2g__Rate__c).setScale(2) ;
        }
        catch( exception e ) { throw new AppException( handleError(e, accCurrency) ); }
    }

    
    /** 
     * Function to Convert value from one currency to another
     **/
    public static decimal convertFromTo( decimal value, String fromCurrencyIsoCode, String toCurrencyIsoCode )
    {
		return convertFromTo( value,  fromCurrencyIsoCode, toCurrencyIsoCode, system.today() );
    }
    /** 
     * Function to Convert value from one currency to another
     **/
    public static decimal convertFromTo( decimal value, String fromCurrencyIsoCode, String toCurrencyIsoCode, date exchangeRateDate )
    {
       	testValue(value);
        try
        {    
            if( fromCurrencyIsoCode == toCurrencyIsoCode )
            {
                return value.setscale(2);
            }
            getAccCurrencies( new Set<String>{FromCurrencyIsoCode, toCurrencyIsoCode});
            // CONVERT FROM HOME
            if( accountingCurrencies.get(fromCurrencyIsoCode).c2g__Home__c )
            {
            	decimal rate = findRateForDate( accountingCurrencies.get(toCurrencyIsoCode), exchangeRateDate );
                return (value * rate).setScale(2);
            }
            // CONVERT TO HOME
            else if( accountingCurrencies.get(toCurrencyIsoCode).c2g__Home__c )
            {
            	decimal rate = findRateForDate( accountingCurrencies.get(fromCurrencyIsoCode), exchangeRateDate );
                return (value / rate).setScale(2);
            }
            // CONVERT FROM ONE CURRENCY TO ANOTHER
        	decimal rate1 = findRateForDate( accountingCurrencies.get(toCurrencyIsoCode), exchangeRateDate );
            decimal tempVar = value * rate1;
            
        	decimal rate2 = findRateForDate( accountingCurrencies.get(fromCurrencyIsoCode), exchangeRateDate );
            return (tempVar / rate2).setScale(2);
        }
        catch( exception e ) { throw new AppException( handleError( e, fromCurrencyIsoCode, toCurrencyIsoCode) );}
    }
    

    /** 
     * 	Find Rate for Date
     *	------------------
     *	Find exchange rate for a given currency on the specified date.
     **/
    public static decimal findRateForDate( c2g__codaAccountingCurrency__c curr, date exchangeRateDate )
    {
       	testValue(curr);
       	// Exchange rates are ordered by start date so the first one that is before the specificed date is the correct rate to use.
       	for( c2g__codaExchangeRate__c exRate : curr.c2g__exchangeRates__r )
       	{
       		log.debug( 'Exchange date: ' + exRate.c2g__StartDate__c + ' effective date: ' + exchangeRateDate );
       		if( exRate.c2g__StartDate__c <= exchangeRateDate )
       		{
       			return exRate.c2g__Rate__c.setScale(2);
       		}	
       	}
		throw new AppException( 'Exchange rate could not be found for ' + curr.name + ' on ' + exchangeRateDate );       	
    }
    
    /*************************************
     * 	Accounting Currency Retrieval    *
     *************************************/
    
    /** 
     * Function to get accounting currency for single supplied iso code
     **/
    public static Map<String,c2g__codaAccountingCurrency__c> getAccCurrency( String currencyCode )
    {
    	if( currencyCode == null )
    	{
    		throw new AppException('Currency cannot be null.');
    	}
        return getAccCurrencies( new set<String>{currencyCode} );
    }
    // Using the acc currency id
    public static Map<Id,c2g__codaAccountingCurrency__c> getAccCurrency( Id accCurrency )
    {
    	if( accCurrency == null )
    	{
    		throw new AppException('Currency cannot be null.');
    	}
        return getAccCurrencies( new set<id>{accCurrency} );
    }
       

    /** 
     * Function to get all accounting currencies 
     **/
    public static map<String,c2g__codaAccountingCurrency__c> getAllAccCurrencies()
    {
        return getAccCurrencies( new set<String>() );
    }                
    public static map<id,c2g__codaAccountingCurrency__c> getAllAccCurrenciesById()
    {
        return getAccCurrencies( new set<Id>() );
    }                
    

    /** 
     *	Get Accounting Currencies
     *	-------------------------
     * 	Function to get accounting currency for supplied iso codes, if this has been previously called then
     *	the new currency codes are added to the existed one.
     **/
    public static map<String,c2g__codaAccountingCurrency__c> getAccCurrencies( Set<String> currencyCodes )
    {
        if( accountingCurrencies == null )
        {
            accountingCurrencies =  new map<String, c2g__codaAccountingCurrency__c >();
        }
        // If code has not been previously loaded or we're bringing back all code (currencyCodes.isEmpty() )
        if( !accountingCurrencies.keyset().containsAll(currencyCodes) || currencyCodes.isEmpty() )
        {
        	currencyCodes.addAll( accountingCurrencies.keyset() );
            list<c2g__codaAccountingCurrency__c> tempCurrList = getAccCurrenciesFromDB( currencyCodes );
            for (c2g__codaAccountingCurrency__c curr : tempCurrList)    
            {
                accountingCurrencies.put(curr.CurrencyIsoCode , curr);
            }
            return accountingCurrencies;                                                
        }
        return accountingCurrencies;
    }
    
    public static map<id, c2g__codaAccountingCurrency__c> getAccCurrencies( Set<Id> currencyIds )
    {
        if( accountingCurrenciesById == null )
        {
            accountingCurrenciesById =  new map<Id, c2g__codaAccountingCurrency__c >();
        }
        // If code has not been previously loaded or we're bringing back all code (currencyCodes.isEmpty() )
        if( !accountingCurrenciesById.keyset().containsAll(currencyIds) || currencyIds.isEmpty() )
        {
         	currencyIds.addAll( accountingCurrenciesById.keyset() );
            list<c2g__codaAccountingCurrency__c> tempCurrList = getAccCurrenciesIdsFromDB( currencyIds );
            for (c2g__codaAccountingCurrency__c curr : tempCurrList)    
            {
                accountingCurrenciesById.put( curr.id , curr );
            }
            return accountingCurrenciesById;                                                
        }
        return accountingCurrenciesById;
    }
    

	/** 
 	 * SOQL statement to bring back currenies and ex rates
	 **/
	private static list<c2g__codaAccountingCurrency__c> getAccCurrenciesFromDB( Set<String> currencyCodes )
	{
		boolean getAll = ( currencyCodes.isEmpty() ? true : false );      
		currencyCodes.addAll(accountingCurrencies.keySet());
     
     	String dbQuery = 'Select Id,								'+
                         '		 name,								'+
                         '		 CurrencyIsoCode,					'+
                         '		 c2g__Home__c,						'+
                         '		 ( Select c2g__Rate__c,				'+
                         '    	     c2g__StartDate__c				'+
                         '    	     From c2g__ExchangeRates__r		'+
                         '   	 order By c2g__StartDate__c desc )	'+	 //descending so relevant exchange rates listed first
                    	 '  From c2g__codaAccountingCurrency__c		'+
        				 ' Where c2g__OwnerCompany__c = \'' + FFUtil.getCurrentCompany().Id + '\' ';
        dbQuery += ( getall ? '' :  
        				 '   and CurrencyIsoCode IN :currencyCodes');
        
	    return Database.query( dbQuery );                                                       
	}
	private static list<c2g__codaAccountingCurrency__c> getAccCurrenciesIdsFromDB( Set<id> currencyIds)
	{

        boolean getAll = ( currencyIds.isEmpty() ? true : false );      
        currencyIds.addAll(accountingCurrenciesById.keySet());
     
        String dbQuery = 'Select Id,								'+
                         '       name,								'+
                         '       CurrencyIsoCode,					'+
                         '       c2g__Home__c,						'+
                         '       ( Select c2g__Rate__c,				'+
                         '           c2g__StartDate__c				'+
                         '           From c2g__ExchangeRates__r		'+
                         '       order By c2g__StartDate__c desc )	'+   //descending so relevant exchange rates listed first
                         '  From c2g__codaAccountingCurrency__c		'+
                         ' Where c2g__OwnerCompany__c = \'' + FFUtil.getCurrentCompany().Id + '\' ';
        dbQuery += ( getall ? '' :  
                         '   and Id in :currencyIds');
        
	    return Database.query( dbQuery );                                                       
	}
   
   
   /************************** 
     * Error Handling function
     **/
    public static void testValue( decimal value )
    {
     	if( value == null )
    	{
    		 throw new AppException( 'Value cannot be null.' );
    	}
    }
    public static void testValue( sObject value )
    {
     	if( value == null )
    	{
    		 throw new AppException( 'Value cannot be null.' );
    	}
    }
    
    public static String handleError( exception e , String currencyIsoCode )
    {
    	String errorMsg;
   		if( getAccCurrency(currencyIsoCode).get(currencyIsoCode) == null )
    	{
    		errorMsg = 'Currency ' + currencyIsoCode + ' not in Accounting currencies. ';
    	}
    	else if ( getAccCurrency(currencyIsoCode).get(currencyIsoCode).c2g__ExchangeRates__r == null )
    	{
    		errorMsg = 'Exchange rates for Currency ' + currencyIsoCode + ' not in Accounting currencies. ';
    	}
    	else
    	{
    		errorMsg = 'Unexpected error retrieving currency  ' + currencyIsoCode + ' : ' + e.getMessage();
    	}
        Log.error( errorMsg );
        return errorMsg;
    }

    public static String handleError( exception e , Id accCurrency )
    {
    	String errorMsg;
    	log.debug('Currency being tested');
    	log.debug(accCurrency);
   		if( getAccCurrency(accCurrency).get(accCurrency) == null )
    	{
    		errorMsg = 'Currency ' + accCurrency + ' not in Accounting currencies. ';
    	}
    	else if ( getAccCurrency(accCurrency).get(accCurrency).c2g__ExchangeRates__r == null )
    	{
    		errorMsg = 'Exchange rates for Currency ' + accCurrency + ' not in Accounting currencies. ';
    	}
    	else
    	{
    		errorMsg = 'Unexpected error retrieving currency  ' + accCurrency + ' : ' + e.getMessage();
    	}
        Log.error( errorMsg );
        return errorMsg;
    }

    public static String handleError( exception e , String fromCurrencyIsoCode, String toCurrencyIsoCode )
    {
		String errorMsg = '';
    	if( accountingCurrencies.get(fromCurrencyIsoCode) == null )
    	{
    		errorMsg = 'Currency ' + fromCurrencyIsoCode + ' not in Accounting currencies. /n';
    	}
    	else if( accountingCurrencies.get(toCurrencyIsoCode) == null )
    	{
    		errorMsg = 'Currency ' + toCurrencyIsoCode + ' not in Accounting currencies./n';
    	}
        if ( getAccCurrency(fromCurrencyIsoCode).get(fromCurrencyIsoCode).c2g__ExchangeRates__r == null )
    	{
    		errorMsg = 'Exchange rates for Currency ' + fromCurrencyIsoCode + ' not in Accounting currencies./n';
    	}
        else if ( getAccCurrency(toCurrencyIsoCode).get(toCurrencyIsoCode).c2g__ExchangeRates__r == null )
    	{
    		errorMsg = 'Exchange rates for Currency ' + toCurrencyIsoCode + ' not in Accounting currencies. /n';
    	}
    	else if ( errorMsg == '' )
    	{
    		errorMsg = 'Unexpected error retrieving currencies  ' + toCurrencyIsoCode + ', ' + fromCurrencyIsoCode + ' : ' + e.getMessage();
    	}
        Log.Error( errorMsg );
        return errorMsg;    
    }
     
    /******************
     * Test Methods
     */    
   	@isTest (seeAllData = true)
   	private static void testCurrencyHelper()
   	{
   		if( !TestHelper.isDevOrg() ) return;
   		
   		c2g__codaAccountingCurrency__c dol = new c2g__codaAccountingCurrency__c ( c2g__DecimalPlaces__c = 2, 
   																				  Name = ' KWD', 
 																				  CurrencyIsoCode = 'KWD');
 		c2g__codaAccountingCurrency__c yen = new c2g__codaAccountingCurrency__c ( c2g__DecimalPlaces__c = 2, 
   																				  Name = ' JPY', 
 																				  CurrencyIsoCode = 'JPY');
 		upsert new c2g__codaAccountingCurrency__c[] { dol, yen};
		
		c2g__codaExchangeRate__c dolEx = new c2g__codaExchangeRate__c( c2g__StartDate__c = date.today(), 
																	   c2g__Rate__c = 2, 
																	   c2g__ExchangeRateCurrency__c = dol.id,
																	   CurrencyIsoCode = 'KWD');
		c2g__codaExchangeRate__c yenEx = new c2g__codaExchangeRate__c( c2g__StartDate__c = date.today(), 
																	   c2g__Rate__c = 4, 
																	   c2g__ExchangeRateCurrency__c = yen.id,
																	   CurrencyIsoCode = 'JPY'); 	
		insert new c2g__codaExchangeRate__c[] { dolEx, yenEx};

   		System.assert( CurrencyHelper.convertFromHome(10, 'GBP') == 10);
  		System.assert( CurrencyHelper.convertFromHome(10, 'KWD') == 20);
        System.assert( CurrencyHelper.convertFromHome(10, dol.id ) == 20);
		System.assert( CurrencyHelper.convertFromHome(10, 'JPY') == 40);
		System.assert( CurrencyHelper.convertFromHome(10, yen.id) == 40);
   		System.assert( CurrencyHelper.convertToHome(10, 'GBP') == 10 );
   		System.assert( CurrencyHelper.convertToHome(10, 'KWD') == 5);
   		System.assert( CurrencyHelper.convertToHome(10, dol.id) == 5);
   		System.assert( CurrencyHelper.convertToHome(10, 'JPY') == 2.5);
   		System.assert( CurrencyHelper.convertToHome(10, yen.id ) == 2.5);
   		System.assert( CurrencyHelper.convertFromTO(10, 'GBP', 'GBP') == 10);
   		System.assert( CurrencyHelper.convertFromTO(10, 'GBP', 'KWD') == 20);
   		System.assert( CurrencyHelper.convertFromTO(10,'KWD','GBP') == 5);
   		System.assert( CurrencyHelper.convertFromTO(10,'KWD','JPY') == 20);
   		System.assert( CurrencyHelper.convertFromTO(10,'JPY','KWD') == 5);
   		
   		try { CurrencyHelper.convertFromHome(10,'XXX'); } catch( exception e){ /* do nothing */ }
 	  	try { CurrencyHelper.convertToHome(10,'XXX'); } catch( exception e){ /* do nothing */ }
 	  	try { CurrencyHelper.convertFromTO(10,'XXX','YYY'); } catch( exception e){ /* do nothing */ }	
   	}
}