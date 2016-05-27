/**
* DynamicFieldRef
* ===============
* Class to hold references to Dynamically ref custom fields in env
*
* 1/3/2013	Luis Valenzuela
*
**/
public with sharing class DynamicFieldRef 
{
	/* custom OPPRTUNITY fields */
	public static String OPP_SUBCONTRACTOR_LABOR_COST_FIELD = 'Subcontractor_Labour_Cost__c';										 
	public static String OPP_CALC_SUBCONTRACTOR_LABOR_COST_FIELD = 'Calculated_Subcontractor_Labour_Cost__c';
	public static String OPP_SUBCONTRACTOR_EXP_FIELD = 'Subcontractor_Expenses__c';	
	public static String OPP_SUBCONTRACTOR_EXP2_FIELD = 'Subcontractor_Expenses2__c';	
	public static String OPP_PASS_THROUGH_COSTS_FIELD = 'Pass_Through_Costs__c';
	public static String OPP_PASS_THROUGH_COSTS2_FIELD = 'Pass_Through_Costs2__c';
	public static String OPP_CALC_INT_LABOUR_COST_FIELD = 'Calculated_Internal_Labour_Cost__c';
	public static String OPP_INT_LABOUR_COST_FIELD = 'Proposed_Internal_Labor_Cost__c';
	
	/* custom PROJECT fields */
	public static String PROJ_CALC_DB_CHARGE_APPLIED_FIELD = 'Calculated_Database_Charge_Applied__c';
	public static String PROJ_CALC_ADMIN_CHARGE_APPLIED_FIELD = 'Calculated_Admin_Charge_Applied__c';
	public static String PROJ_CALC_SUBCONTRACTOR_LABOR_COST_FIELD = 'Calculated_Subcontractor_Labour_Cost__c';	
	public static String PROJ_SUBCONTRACTOR_EXP2_FIELD = 'Subcontractor_Expenses_2__c';	
	public static String PROJ_PASS_THROUGH_COSTS2_FIELD = 'Pass_Through_Costs2__c';
	public static String PROJ_PROJECT_CODE_FIELD = 'Project_Code__c';
	public static String PROJ_PROJECT_VALUE_FIELD = 'Project_Value__c';
	
}