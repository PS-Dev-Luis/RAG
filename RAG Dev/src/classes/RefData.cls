/**
 *	RefData
 *	=======
 *	Helper class to act as a central point for reference data.
 *
 **/
public with sharing class RefData 
{

	/////////////////////////////////////////////////////
	// Standard Reference Data
	/* Billing Event Item */
	public static final String BILL_EVENT_ITEM_CAT_TIMECARD = 'Timecard';
	public static final String BILL_EVENT_ITEM_CAT_MILESTONE = 'Milestone';
	public static final String BILL_EVENT_ITEM_CAT_EXPENSE = 'Expense';
	public static final String BILL_EVENT_ITEM_CAT_MISCADJ = 'Miscellaneous Adjustment';

	/* Currency */
	public static final String CURRENCY_ISO_USD = 'USD';
	public static final String CURRENCY_ISO_GBP = 'GBP'; 
	public static final String CURRENCY_DEFAULT = CURRENCY_ISO_USD;

	/* Expense Report */
	public static final String EXPENSE_REPORT_STATUS_DRAFT = 'Draft';
	public static final String EXPENSE_REPORT_STATUS_SUBMITTED = 'Submitted';
	public static final String EXPENSE_REPORT_STATUS_APPROVED = 'Approved';
	public static final String EXPENSE_REPORT_STATUS_REJECTED = 'Rejected';
	public static final String EXPENSE_REPORT_DESC_DRAFT = 'Description';
	
	/* GL Account */
	public static final String GL_TYPE_BALANCE = 'Balance Sheet';
	public static final String GL_TYPE_PROFIT_LOSS = 'Profit and Loss';
	public static final String GL_TYPE_RETAINED_EARNINGS = 'Retained Earnings';
		
	/* Invoice */
	public static final String INVOICE_CATEGORY_PROF_FEES = 'Professional Fees';
	public static final String INVOICE_CATEGORY_MILESTONE = 'Milestone(s)';
	public static final String INVOICE_CATEGORY_DB_CHARGE = 'Database Charges';
	public static final String INVOICE_CATEGORY_ADMIN_CHARGE = 'Administration Charges';
	public static final String INVOICE_CATEGORY_EXPENSE = 'Out of Pocket Expenses';
	public static final String INVOICE_CATEGORY_MISCADJ = 'Miscellaneous Adjustments';

	/* Journal */
	// Type
	public static final String JOURNAL_TYPE_MANUAL = 'Manual Journal';
	// State
	public static final String JOURNAL_STATUS_IN_PROGRESS = 'In Progress';

	/* Journal Lines*/
	// Line Type
	public static String JOURNAL_LINE_TYPE_GENERAL_LEDGER = 'General Ledger Account';

	/* Milestone */
	// Names
	public static final String MS_NAME_PROF_FEE ='Professional Fees';
	public static final String MS_NAME_DB_CHARGE = 'Database Charge -';
	public static final String MS_NAME_ADMIN_CHARGE = 'Administration Charge -';
	public static final String MS_NAME_SUBCONTRACTOR_FEE = 'Subcontractor Fee';
	public static final String MS_NAME_SUBCONTRACTOR_EXP = 'Subcontractor Expenses';
	public static final String MS_NAME_PASS_THROUGH_COSTS = 'Pass Through Costs';
	public static final String MS_NAME_EXPENSES = 'OOPE Charge -';

	/* Opportunity */ 
	public static final String OPP_STATUS_PROSPECTING ='Prospecting';
	public static final String OPP_STATUS_CLOSED_WON = 'Closed Won';
	public static final String OPP_STATUS_CLOSED_LOST = 'Closed Lost';

	/* Products (fpsai) */ 
	public static final String PROD_PROF_FEE_MS_NAME ='Professional Fees';
	public static final String PROD_OUT_OF_POCKET_EXP = 'Out of pocket expenses';
	public static final String PROD_PASS_THROUGH_COSTS = 'Pass Through Costs';
	public static final String PROD_DB_CHARGE = 'Database Charge';
	public static final String PROD_ADMIN_CHARGE = 'Administration Charge';

	/* Project */
	// Billing types
	public static final String PROJ_BT_FIXED_PRICE = 'Fixed Price';
	public static final String PROJ_BT_TIME_AND_MATERIALS = 'Time and Materials';
	public static final String PROJ_BT_RETAINER = 'Retainer';

	/* Resource Requests */
	public static final String RESOURCE_ROLE_ARCHITECT = 'Architect';
	
	/* Schedule */
	public static final String SCHEDULE_PATTERN_8x5 = '8x5';
	public static final String SCHEDULE_PATTERN_10x4 = '10x4';
	public static final String SCHEDULE_PATTERN_0 = '0';
	public static final String SCHEDULE_PATTERN_1 = '1';

	/* Timecard */
	public static final String TIMECARD_STATUS_SAVED = 'Saved';
	public static final String TIMECARD_STATUS_SUBMITTED = 'Submitted';
	public static final String TIMECARD_STATUS_APPROVED = 'Approved';
	public static final String TIMECARD_STATUS_REJECTED = 'Rejected';

	/* User */
	public static final String USER_DEFAULT_EMAIL_ENCODING = 'ISO-8859-1';
	public static final String USER_DEFAULT_LANGUAGE_LOCALE = 'en_US';
	public static final String USER_DEFAULT_LOCALE = 'en_US';
	public static final String USER_DEFAULT_TIME_ZONE= 'America/Indianapolis';

	/* WIP Report */
	public static final String WIP_STATUS_NEW = 'New';
	public static final String WIP_STATUS_PEND = 'Pending';
	public static final String WIP_STATUS_GEN = 'Generated';

	
	/////////////////////////////////////////////////////
	// Generic Ref Data
	/* Approval Status */
	public static final String GEN_APPROVED = 'Approved';	
	
	public static final Id GEN_NULL = null;
	
	public static final String DELIMITER = '|';
	
	public static final String STAGE_IN_PROGRESS = 'In Progress';

	public static final integer CASE_INSENSITIVE_ID_LENGTH = 15;

	/////////////////////////////////////////////////////
	// Custom Reference Data 
	/* Journal Lines*/
	// Line description
	public static final String JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_CRED = 'Subcontractor Fee - Credit';
	public static final String JOURNAL_LINE_DESC_SUBCONTRACTOR_FEE_DEBIT = 'Subcontractor Fee - Debit';
	public static final String JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_CRED = 'Subcontractor Expenses - Credit';
	public static final String JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_DEBIT = 'Subcontractor Expenses - Debit';
	public static final String JOURNAL_LINE_DESC_PASS_THRU_COSTS_CRED = 'Pass Through Costs - Credit';
	public static final String JOURNAL_LINE_DESC_PASS_THRU_COSTS_DEBIT = 'Pass Through Costs - Debit';
	public static final String JOURNAL_LINE_DESC_TIMECARD_CRED = 'Timecard - Credit';
	public static final String JOURNAL_LINE_DESC_TIMECARD_DEBIT = 'Timecard - Debit';
	public static final String JOURNAL_LINE_DESC_MISCADJ_CRED = 'Misc Adj - Credit';
	public static final String JOURNAL_LINE_DESC_MISCADJ_DEBIT = 'Misc Adj - Debit';
	
	public static final String WIP_REPORT_FILTER_TYPE_DATE = 'Date';
	public static final String WIP_REPORT_FILTER_TYPE_PERIOD = 'Period';
		
}