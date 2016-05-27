/*
*	Config class for enabling/disabling triggers associated with CD0387
*
*	Luis Valenzuela 19/02/2013
*/
public with sharing class ConfigSettings 
{

	private static boolean AutoAssignOppResourcesToProject_Disabled = false;
	private static boolean GenerateProjectMilestones_Disabled = false;
	private static boolean RecalculateCostsOnOpportunity_Disabled = false;
	
	private static boolean GenerateProjectJournal_Disabled = false;
	private static boolean GenerateTimecardJournal_Disabled = false;
	private static boolean GenerateMiscAdjJournal_Disabled = false;

	private static boolean GenerateProjectDimension_Disabled = false;
	private static boolean GenerateContactDimension_Disabled = false;
	
	private static boolean OpportunityCompanyValidation_Disabled = false;
	private static boolean RequireDimensions_Disabled = false;
	private static boolean CopyDocNumberToCustomerRef_Disabled = false;
	
	private static boolean CalcuateChargeOnTransaction_Disabled = false;
	private static boolean ConvertCalcuatedChargeOnUpdate_Disabled = true;
	private static boolean CalcuateChargeOnJournal_Disabled = false;
	
	private static boolean refreshSettingsFlag = true;
	
	public static boolean isAutoAssignOppResourcesToProject_Disabled()
	{
		refreshConfig();
		return AutoAssignOppResourcesToProject_Disabled;
	}	
		

	public static boolean isRecalculateCostsOnOpportunity_Disabled()
	{
		refreshConfig();
		return RecalculateCostsOnOpportunity_Disabled;
	}	

	/* Generate Milestones */
	public static boolean isGenerateProjectMilestones_Disabled()
	{
		refreshConfig();
		return GenerateProjectMilestones_Disabled;
	}
	
	/* Generate Journals */
	public static boolean isGenerateProjectJournal_Disabled()
	{
		refreshConfig();
		return GenerateProjectJournal_Disabled;
	}
	public static boolean isGenerateTimecardJournal_Disabled()
	{
		refreshConfig();
		return GenerateTimecardJournal_Disabled;
	}
	public static boolean isGenerateMiscAdjJournal_Disabled()
	{
		refreshConfig();
		return GenerateMiscAdjJournal_Disabled;
	}

	/* Generate Dimensions */
	public static boolean isGenerateProjectDimension_Disabled()
	{
		refreshConfig();
		return GenerateProjectDimension_Disabled;
	}
	public static boolean isGenerateContactDimension_Disabled()
	{
		refreshConfig();
		return GenerateContactDimension_Disabled;
	}
	public static boolean isOpportunityCompanyValidation_Disabled()
	{
		refreshConfig();
		return OpportunityCompanyValidation_Disabled;
	}
	public static boolean isRequireDimensions_Disabled()
	{
		refreshConfig();
		return RequireDimensions_Disabled;
	}
	
	/* General Config */
	public static boolean isCopyDocNumberToCustomerRef_Disabled()
	{
		refreshConfig();
		return CopyDocNumberToCustomerRef_Disabled;
	}
	public static boolean isCalcuateChargeOnTransaction_Disabled()
	{
		refreshConfig();
		return CalcuateChargeOnTransaction_Disabled;
	}
	public static boolean isConvertCalcuatedChargeOnUpdate_Disabled()
	{
		refreshConfig();
		return ConvertCalcuatedChargeOnUpdate_Disabled;
	}
	public static boolean isCalcuateChargeOnJournal_Disabled()
	{
		refreshConfig();
		return CalcuateChargeOnJournal_Disabled;
	}
	
	 
	// Refresh method to bring back config from the Env if not already done in this Ex Context
	public static void refreshConfig()
	{
		if( refreshSettingsFlag )
		{
			pse__Triggers__c refreshedSettings = pse__Triggers__c.getInstance();
			if(null != refreshedSettings )
			{
				AutoAssignOppResourcesToProject_Disabled = refreshedSettings.AutoAssignOppResourcesToProject_Disabled__c;
				GenerateProjectMilestones_Disabled = refreshedSettings.GenerateProjectMilestones_Disabled__c;
				RecalculateCostsOnOpportunity_Disabled = refreshedSettings.RecalculateCostsOnOpportunity_Disabled__c;
				GenerateProjectJournal_Disabled = refreshedSettings.GenerateProjectJournal_Disabled__c;
				GenerateTimecardJournal_Disabled = refreshedSettings.GenerateTimecardJournal_Disabled__c;
				GenerateMiscAdjJournal_Disabled = refreshedSettings.GenerateMiscAdjJournal_Disabled__c;
				GenerateProjectDimension_Disabled = refreshedSettings.GenerateProjectDimension_Disabled__c;
				GenerateContactDimension_Disabled = refreshedSettings.GenerateContactDimension_Disabled__c;
				OpportunityCompanyValidation_Disabled = refreshedSettings.OpportunityCompanyValidation_Disabled__c;
				RequireDimensions_Disabled = refreshedSettings.RequireDimensions_Disabled__c;
				CopyDocNumberToCustomerRef_Disabled = refreshedSettings.CopyDocNumberToCustomerRef_Disabled__c;
				CalcuateChargeOnTransaction_Disabled = refreshedSettings.CalcuateChargeOnTransaction_Disabled__c;
				ConvertCalcuatedChargeOnUpdate_Disabled = refreshedSettings.ConvertCalcuatedChargeOnUpdate_Disabled__c;
				CalcuateChargeOnJournal_Disabled = refreshedSettings.CalcuateChargeOnJournal_Disabled__c;
				// Settings are cached 
				refreshSettingsFlag = false;
				System.Debug(System.Logginglevel.INFO, 'Refreshing Config from Env.');
			}
		}
	}
	
}