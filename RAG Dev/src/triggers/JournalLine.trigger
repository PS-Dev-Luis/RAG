trigger JournalLine on c2g__codaJournalLineItem__c (before insert) 
{
	list<id> journalIds = new list<id>();
	list<id> glaIds = new list<id>();
	for(c2g__codaJournalLineItem__c jrLi : trigger.new)
	{
		journalIds.add(jrLi.c2g__Journal__c);
		glaIds.add(jrLi.c2g__GeneralLedgerAccount__c);
	}

	String query = 'Select 	id,															'+
					'		Name,		 												'+
					'		c2g__Type__c, 												'+
					'		c2g__OriginalJournal__c,									'+ 
					'		c2g__OriginalJournal__r.Id, 								'+
					'		c2g__OriginalJournal__r.c2g__Type__c,						'+
					'		c2g__SourceJournal__c, 										'+
					'		c2g__SourceJournal__r.Id, 									'+
					'		c2g__SourceJournal__r.c2g__Type__c,							'+
					'		(Select	Id,													'+
					'				c2g__Journal__c, 									'+
					'		 		c2g__Value__c, 										'+
					'		 		c2g__HomeValue__c, 									'+
					'		 		c2g__LineNumber__c, 								'+
					'		 		c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c,	'+
					'		 		ffps_0387__Calculated_Charge2__c 					'+
					'			From 													'+
					'				c2g__JournalLineItems__r) 							'+
					'	From 															'+
					'		c2g__codaJournal__c 										';
																	
	map<id,c2g__codaJournal__c> journalsMap = new map<id,c2g__codaJournal__c>( (list<c2g__codaJournal__c>) Database.query( query + 'where id in :journalIds'));

	list<id> reversedJournalIds = new list<id>();
	for(c2g__codaJournal__c jrnl : journalsMap.values() )
	{
		reversedJournalIds.add(jrnl.c2g__OriginalJournal__c);
		reversedJournalIds.add(jrnl.c2g__SourceJournal__c);
	}
	
	map<id,c2g__codaJournal__c> reversedJournalsMap = new map<id,c2g__codaJournal__c>( (list<c2g__codaJournal__c>) Database.query( query + 'where id in :reversedJournalIds'));
	map<String,c2g__codaJournalLineItem__c> revJrnlLinesMap= new map<String,c2g__codaJournalLineItem__c>();
	for(c2g__codaJournal__c jrn : reversedJournalsMap.values())
	{
		for(c2g__codaJournalLineItem__c jrnLin : jrn.c2g__JournalLineItems__r)
		{
			revJrnlLinesMap.put( jrn.Name + jrnLin.c2g__LineNumber__c,jrnLin );
		}
	}

	// Carry the the calculated charge from the reversed Journal to the new Journal
	for(c2g__codaJournalLineItem__c jrnLin : trigger.new)
	{ 
		c2g__codaJournal__c origJrnl = journalsMap.get( jrnLin.c2g__Journal__c );
		id revJrnlId = origJrnl.c2g__OriginalJournal__c != null ? origJrnl.c2g__OriginalJournal__r.id :
					   origJrnl.c2g__SourceJournal__c != null ? origJrnl.c2g__SourceJournal__r.id : null;
		if(revJrnlId != null)
		{
			c2g__codaJournal__c revJrnl = reversedJournalsMap.get( revJrnlId );
			c2g__codaJournalLineItem__c revJrnlLin = revJrnlLinesMap.get(revJrnl.name + jrnLin.c2g__LineNumber__c);
			if(revJrnlLin !=  null && revJrnlLin.ffps_0387__Calculated_Charge2__c != null)
			{
				jrnLin.ffps_0387__Calculated_Charge2__c = -revJrnlLin.ffps_0387__Calculated_Charge2__c;
			}
		} 		
	}


	// [LV20150722] Allow for custom multiplier to be added to Journals if no Calculated charge set.
	map<String,decimal> jrnMultiMap = new map<String,decimal>();
	for( JournalGlaMultipliers__c jm : JournalGlaMultipliers__c.getAll().values() )
	{
		jrnMultiMap.put(jm.GLA_Report_Code__c, jm.Multiplier__c );		
	}

	log.debug('jrnMap' + jrnMultiMap );
	// Don't bother if custom setting have not been set
	if( jrnMultiMap.size() > 0 )
	{
		map<id,c2g__codaGeneralLedgerAccount__c>  glaMap = 
				new map<id,c2g__codaGeneralLedgerAccount__c>( [select id,c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where id in:glaIds]);
		
		for( c2g__codaJournalLineItem__c jrnLin : trigger.new )
		{ 
			log.debug('Jrn ' + jrnLin );
			decimal multiplier = jrnMultiMap.get( glaMap.get( jrnLin.c2g__GeneralLedgerAccount__c ).c2g__ReportingCode__c ); 
			log.debug('Mulitplier' + multiplier );
			if( jrnLin.Calculated_Charge2__c == null && multiplier != null )
			{
				log.debug('CC ' + jrnLin.Calculated_Charge2__c );
				jrnLin.Calculated_Charge2__c = jrnLin.c2g__Value__c * multiplier;
			}
		}
	}
}