@isTest (seeAllData = true)
public with sharing class TestCalcualtedChargeFixes 
{

	@isTest (seeAllData = true)
	public static void testJournalFix()
	{
		CalculatedChargeJournalCleanseBatch batch = new CalculatedChargeJournalCleanseBatch();
		batch.testRun = false;
		Database.executeBatch( batch, 10 ); 		
	}
	
	@isTest (seeAllData = true)
	public static void testTxLiFix()
	{
		CalculatedChargeTransactionCleanseBatch batch = new CalculatedChargeTransactionCleanseBatch();
		batch.testRun = false;
		Database.executeBatch( batch, 10 ); 
	}

}