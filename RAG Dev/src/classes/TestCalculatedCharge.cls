@isTest (seeAllData = true)
public with sharing class TestCalculatedCharge 
{
	
    @istest 
    static void testJournalInsert()
    {
		/* Create 1st Journal and line */
		c2g__codaJournal__c jrn = createJournal();
															
		insert jrn;													

		list<c2g__codaJournalLineItem__c> newJournalLines = new list<c2g__codaJournalLineItem__c>();
		for(integer i = 0; i < 10; i++)
		{
			c2g__codaJournalLineItem__c	jrnLin = createJournalLine(jrn);
			jrnLin.c2g__Value__c = i +1 ;
			jrnLin.calculated_charge2__c = i +1 ;
			newJournalLines.add(jrnLin);
		}

    	insert newJournalLines;

		/* Create Cancelling Journal and lines */
		//@TODO I hate core, useless API, why would you not just have a cancelJournal service??? 
		//c2g.CODAAPICommon_6_0.Context context = new c2g.CODAAPICommon_6_0.Context();
        //context.token = EncodingUtil.convertToHex( Crypto.generateDigest('SHA1',
	    //           		Blob.valueOf('0000000000000000C000000000000046' + UserInfo.getUserId() + 
	    //            			'PROBABLEMENTE EL MEJOR SOFTWARE DE CONTABILIDAD EN EL MUNDO')));
		// c2g.CODAAPIJournal_6_0.cancelJournal( context, c2g.CODAAPICommon.getRef( jrn.id, null ) );
    	
		String query = 	'Select id,											'+
						'		Name,		 								'+
						'		c2g__Type__c, 								'+
						'		c2g__OriginalJournal__c,					'+ 
						'		c2g__OriginalJournal__r.Id, 				'+
						'		c2g__OriginalJournal__r.c2g__Type__c,		'+
						'		c2g__SourceJournal__c, 						'+
						'		c2g__SourceJournal__r.Id, 					'+
						'		c2g__SourceJournal__r.c2g__Type__c,			'+
						'		(Select	Id,									'+
						'				c2g__Journal__c, 					'+
						'		 		c2g__HomeValue__c, 					'+
						'		 		c2g__LineNumber__c, 				'+
						'		 		ffps_0387__Calculated_Charge2__c 	'+
						'			From 									'+
						'				c2g__JournalLineItems__r) 			'+
						'	From 											'+
						'		c2g__codaJournal__c 						';
																		
		id jrnId = jrn.id;
		map<id,c2g__codaJournal__c> journalsMap = new map<id,c2g__codaJournal__c>( (list<c2g__codaJournal__c>) Database.query( query + 'where id = :jrnId'));
		log.debug(journalsMap); 
    }
    
	public static c2g__codaJournal__c createJournal( )
	{
		return new c2g__codaJournal__c( CurrencyIsoCode = 'GBP',
  										// c2g__JournalCurrency__c = (curr != null ? curr.Id : null),
  										c2g__Type__c = RefData.JOURNAL_TYPE_MANUAL,
										c2g__JournalDate__c = Date.newInstance(2014,01,01),
										c2g__JournalStatus__c = RefData.JOURNAL_STATUS_IN_PROGRESS,
										c2g__Reference__c = 'Test Journal',
										c2g__JournalDescription__c = 'Test Journal',
										ffgl__DeriveCurrency__c = true,
										ffgl__DerivePeriod__c = true);
	}
	public static c2g__codaJournalLineItem__c createJournalLine(c2g__codaJournal__c jrn )
	{
		return  new c2g__codaJournalLineItem__c(	c2g__LineDescription__c = RefData.JOURNAL_LINE_DESC_SUBCONTRACTOR_EXP_CRED,
													c2g__LineType__c = RefData.JOURNAL_LINE_TYPE_GENERAL_LEDGER,
													c2g__Value__c = 0,
													calculated_charge2__c =	0,
													c2g__Journal__c = jrn.id,
													c2g__GeneralLedgerAccount__c =  CustomSettings.subContractorFeeCreditGLid); 
	}
}