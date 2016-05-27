/**
*	SalesInvoiceComponentsExpController
*	==================================
*	Controller responsible for creating list of expense reports to be used by the SalesInvoiceExp.component
* 	this controller uses a list of billingevents retrieved by the SalesInvoiceControllerCustom and then creates
* 	an ordered list to be added to the Sales invoice.
*
*	Luis Valenzuela 18/03/2013
*
*/
global with sharing class SalesInvoiceComponentsExpController 
{
	// Invoice line billing events relating to Milestones
	public list<pse__Billing_Event_Item__c> expenseBillEvents;
	// The expense Report
	public wrappedExpenseReport[] expReportsSorted {get; private set;}
	private static String DELIM = RefData.DELIMITER;
	
	public list<pse__Billing_Event_Item__c> getExpenseBillEvents()
	{
		return expenseBillEvents;
	}
  
	public void setExpenseBillEvents(list<pse__Billing_Event_Item__c> billEvents)
	{

  		if( billEvents.isEmpty() ) return;
		this.expReportsSorted = new List<wrappedExpenseReport>();
  		
  		// get Expense ids
  		Set<Id> expenseIds = new set<Id>();
  		for(pse__Billing_Event_Item__c bei : billEvents)
	  	{
    		expenseIds.add( bei.pse__Object_Id__c );
	  	}
		if(expenseIds.isEmpty()) return;
			  	
  		// get expenses for supplied Billing Events
	  	List<pse__Expense_Report__c> dbExpReports = new List<pse__Expense_Report__c>([
													    SELECT 
													    	Id,
												           	CurrencyIsoCode,
												           	Name,
												           	pse__Total_Billable_Amount__c,
												           	pse__First_Expense_Date__c,
												           	pse__Last_Expense_Date__c,
												           	pse__Resource__c,
												           	pse__Resource__r.LastName,
												           	pse__Resource__r.FirstName,
												           	(SELECT 
											           			Id,
											                   	pse__Expense_Report__c,
											                   	pse__Type__c,
											                   	pse__Expense_Date__c,
											                   	pse__Description__c,
											                   	pse__Billable_Amount__c
											            	FROM 
											            		pse__Expense_Lines__r)
													      FROM 
												      		pse__Expense_Report__c
													     WHERE 
													     	Id IN (SELECT 
												  						pse__Expense_Report__c
								      							  	FROM 	
								      							  		pse__Expense__c
								     							 	WHERE 	
								     							 		Id IN :expenseIds) ]); 
  		if(dbExpReports.isEmpty()) return;
  
    	// - Expenses grouped by Expense Report
		// - [Sub-Heading] Resource (Asc-1 (last,first)), Start Date (Asc-2), End Date (Asc-3), Total this Invoice, Expense Report Name
		// - [Detail] Expenses {Expense Type (Asc), Date (Asc) Amount, Description}
		// include record Id in the sort to ensure uniqueness
		String expReportHashkey = '';
		String expLinHashkey = '';
	
		map<String, pse__Expense__c> expensesHashkeyMap = new Map<String, pse__Expense__c>();
		list<pse__Expense__c> sortedExpenses = new List<pse__Expense__c>();
		map<String, wrappedExpenseReport> expenseReportHashkeyMap = new Map<String, wrappedExpenseReport>();
   		  
		for(pse__Expense_Report__c expRep : dbExpReports)
		{
		    // create expenses sortable key and add to map
		    for(pse__Expense__c expense : expRep.pse__Expense_Lines__r)
		    {
		    	expLinHashkey = expense.pse__Type__c + DELIM +
        	             			SalesInvoiceHelper.getDateStringYYYYMMDD(expense.pse__Expense_Date__c) + DELIM +
                    	 				expense.Id;
 				expensesHashkeyMap.put( expLinHashkey, expense );
		    }
			// Create list of ordered Expenses
		    sortedExpenses = (list<pse__Expense__c>) SalesInvoiceHelper.getSortedList( expensesHashkeyMap );
		    
			// Create Expense Report Sortable key and add to map 
		    expReportHashkey = 	expRep.pse__Resource__r.LastName + DELIM +
	                           		expRep.pse__Resource__r.FirstName + DELIM +
	                           			SalesInvoiceHelper.getDateStringYYYYMMDD(expRep.pse__First_Expense_Date__c) + DELIM +
	                           				SalesInvoiceHelper.getDateStringYYYYMMDD(expRep.pse__Last_Expense_Date__c) + DELIM +
	                           					expRep.Id;
	        expenseReportHashkeyMap.put(expReportHashkey, new wrappedExpenseReport( expRep, sortedExpenses ) );
	    }
		  
		// Created sorted list of Expense Reports
		this.expReportsSorted = SalesInvoiceHelper.getSortedList( expenseReportHashkeyMap );

	} // end of setSalesInvoice

	
	public class wrappedExpenseReport 
	{
		public pse__Expense_Report__c expenseReport {get; set;}
  		public List<pse__Expense__c> expenses {get; set;}
  		public Decimal invoiceAmount {get; set;}
  
		//This is the contructor method. When we create a new cContact object we pass a Contact that is set to the con property. 
  		// We also set the selected value to false
	  	public wrappedExpenseReport(pse__Expense_Report__c expRep, List<pse__Expense__c> exps ) 
	  	{
			invoiceAmount = 0;
			expenseReport = expRep;
			expenses = exps.clone();
			// Calculate totals
			for(pse__Expense__c exp : exps)
			{
			  invoiceAmount += exp.pse__Billable_Amount__c;
			}
		}
	} // end of inner class

} // end of class