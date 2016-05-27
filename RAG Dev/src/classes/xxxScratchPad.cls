public with sharing class xxxScratchPad 
{
/*
       helper.Journal = new c2g__codaJournal__c();
                helper.Journal.c2g__JournalCurrency__c = (ID)line.getSObject('c2g__Purchase'+document+'__r').get('c2g__'+document+'Currency__c');
                helper.Journal.c2g__Period__c = (ID)line.getSObject('c2g__Purchase'+document+'__r').get('c2g__Period__c');
                helper.Journal.c2g__JournalDate__c = (Date)line.getSObject('c2g__Purchase'+document+'__r').get('c2g__'+document+'Date__c');
                helper.Journal.c2g__Reference__c = (String)line.getSObject('c2g__Purchase'+document+'__r').get('Name');
                helper.Journal.put( 'Payable'+document+'__c', (ID)line.get('c2g__Purchase'+document+'__c') );
                helper.Journal.ffgl__DeriveCurrency__c = false;
                helper.Journal.ffgl__DerivePeriod__c = false;
                helper.Journal.c2g__JournalDescription__c = 'O/S VAT Reversal';
                helper.Journal.c2g__Type__c = 'Manual Journal';
            c2g__codaJournalLineItem__c journalLine = new c2g__codaJournalLineItem__c();
            journalLine.c2g__LineNumber__c = this.Lines.size()+1;
            journalLine.c2g__LineType__c = 'Tax Code';
            // by setting this custom field, when the transaction line item trigger fires, it will get set correctly on the line
            journalLine.DocumentTaxableValue__c = round( taxableValue );
            journalLine.c2g__Value__c = round( value );
            journalLine.c2g__TaxCode__c = (ID)line.get('c2g__InputVATCode__c');
            journalLine.c2g__GeneralLedgerAccount__c = glaId;
            
            this.Lines.add( journalLine );	
 		Pass Through Costs
 	*/
	
}