/**
*	SalesInvoiceHelper
*	===================
*	Helper class for the various components of the customSalesinvoicePrint page
*
*	Luis Valenzuela 18/03/2013
*
*/public with sharing class SalesInvoiceHelper 
{
	// Utility method for creating YYYYMMDD date string
	public static String getDateStringYYYYMMDD(Date dateValue)
	{
		  if(dateValue == null) return '';

		  return '' + dateValue.year() + (dateValue.month() < 10 ? '0':'' ) + 
		  			dateValue.month() + (dateValue.day() < 10 ? '0':'') + dateValue.day() ;
	}
	
	// Utility method to sort a list of sObjects on a associated string value
	public static list<sObject> getSortedList(map<String, sObject> mapToSort)
	{
		list<sObject> returnList = new list<sObject>();	
		list<String> keyList = new list<String>();
   		keyList.addAll( mapToSort.KeySet() );
		keylist.sort();
		for(String key : keyList )
  		{
    		returnList.add( mapToSort.get(key) );
  		}
  		return returnList;
	}
	
	// Utility method to sort a list of sObjects on a associated string value 
	public static list<SalesInvoiceComponentsExpController.wrappedExpenseReport> 
		getSortedList(map<String, SalesInvoiceComponentsExpController.wrappedExpenseReport> mapToSort)
	{
		list<SalesInvoiceComponentsExpController.wrappedExpenseReport> returnList = 
			new list<SalesInvoiceComponentsExpController.wrappedExpenseReport>();	
		list<String> keyList = new list<String>();
   		keyList.addAll( mapToSort.KeySet() );
		keylist.sort();
		for(String key : keyList )
  		{
    		returnList.add( mapToSort.get(key) );
  		}
  		return returnList;
	}

}