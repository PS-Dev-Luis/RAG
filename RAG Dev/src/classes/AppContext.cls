public with sharing class AppContext 
{
	private static date dateContext = null;
	
	public static String COMPANY_NAME = 'Risk Advisory Group';
	
	private static c2g.CODAAPICommon_7_0.Context apiContext = null;
	private static c2g.CODAAPICommon_6_0.Context api6Context = null;
	
	public static c2g.CODAAPICommon_7_0.Context getApiContext()
	{
		if( apiContext == null )
		{
			String apiToken = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf('0000000000000000C000000000000046' + UserInfo.getUserId() + 'PROBABLEMENTE EL MEJOR SOFTWARE DE CONTABILIDAD EN EL MUNDO')));
			apiContext = new c2g.CODAAPICommon_7_0.Context();
			apiContext.Token = apiToken;
		}
		
		return apiContext;
	}
	
	public static c2g.CODAAPICommon_6_0.Context getApi6Context()
	{ 
		if( api6Context == null )
		{
			String apiToken = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf('0000000000000000C000000000000046' + UserInfo.getUserId() + 'PROBABLEMENTE EL MEJOR SOFTWARE DE CONTABILIDAD EN EL MUNDO')));
			api6Context = new c2g.CODAAPICommon_6_0.Context();
			api6Context.Token = apiToken;
		}
		
		return api6Context;
	}
		

	/**
	 *	Get Date Context
	 *	----------------
	 *	Allow test scripts to specify any time as current date.  
	 */
	public static Date getDateContext()
	{
		if( dateContext == null )
		{
			dateContext = System.today();
		}
		return dateContext;	
	}
	public static void setDateContext( Date currentDate )
	{
		if( Test.isRunningTest() )
		{
			dateContext = currentDate;
		}
	}

}