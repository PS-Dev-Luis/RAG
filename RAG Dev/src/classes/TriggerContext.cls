public with sharing class TriggerContext {

	public static integer counter_proj = 0;

	public static boolean proj_hasRanValidation = false;
	public static boolean proj_hasRanResourceAllocation = false;
	public static boolean proj_hasRanMsCreation = false;
	public static boolean proj_hasRanDimCreation = false;
	public static boolean proj_hasRanJournalCreation = false;
	public static boolean proj_hasRanProjectCodeCreation = false;

	public static boolean rr_hasRan = false;

	public static boolean miscAdj_hasRan = false;

	public TriggerContext() {
		
	}

	public static integer enteringProjTrigger() 
	{
		return TriggerContext.counter_proj++;	
	}

	public static integer leavingProjTrigger() 
	{
		TriggerContext.counter_proj--;
		if(TriggerContext.counter_proj == 0 )
		{
			TriggerContext.proj_hasRanValidation = false;
			TriggerContext.proj_hasRanResourceAllocation = false;
			TriggerContext.proj_hasRanMsCreation = false;
			TriggerContext.proj_hasRanDimCreation = false;
			TriggerContext.proj_hasRanJournalCreation = false;
			TriggerContext.proj_hasRanProjectCodeCreation = false;
		}
		return TriggerContext.counter_proj;
	}

}