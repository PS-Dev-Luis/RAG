@isTest (seeAllData = true)
public with sharing class TestInvoiceLineTrigger 
{
	static id TEST_PRODUCT_ID = '01tb0000000KYZL';

    /**
    *   TEST 1 : Insert Invoice Line With No Dimensions
    *   Test InvoiceLineItem.Trigger after insert of line
    *   =============================================================================
    *   start conditions    - Create a Sales invoice with a single invoice line
    *   action              - Insert new line with null dimensions
    *   end state           - New invoice line should inherit dimensions from existing invoice line
    */  
    @isTest (seeAllData = true)
    public static void InsertInvoiceLineWithNoDimensions() 
    {
		if( !TestHelper.isDevOrg() ) return;
	        
        /* ++++++++++++++++ Setup +++++++++++++++++++ */
        // Grab an account
        Account acc = [Select Id From Account limit 1];
        
        c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
        invoice.c2g__Account__c = [select id from Account limit 1].id;
		insert invoice;
		
		c2g__codaInvoiceLineItem__c line1 = new c2g__codaInvoiceLineItem__c();
		line1.c2g__Invoice__c = invoice.id;
        line1.c2g__Dimension1__c = [Select Id from c2g__codaDimension1__c limit 1].Id;
        line1.c2g__Dimension2__c = [Select Id from c2g__codaDimension2__c limit 1].Id;
        line1.c2g__Dimension3__c = [Select Id from c2g__codaDimension3__c limit 1].Id;  
        Product2 prod = [Select Id from Product2 limit 1];
        line1.c2g__Product__c = TEST_PRODUCT_ID;  
		insert line1;		

        /* ++++++++++++++++ Action ++++++++++++++++++++++++++++ */
        
		System.Test.startTest();
        c2g__codaInvoiceLineItem__c line2 = new c2g__codaInvoiceLineItem__c();
        line2.c2g__Product__c = TEST_PRODUCT_ID;  
		line2.c2g__Invoice__c = invoice.id;
		insert line2;		
		
        System.Test.stopTest();
        
        c2g__codaInvoiceLineItem__c line2DB = [  Select id,
        												c2g__Dimension1__c,
        												c2g__Dimension2__c,
        												c2g__Dimension3__c
        											from c2g__codaInvoiceLineItem__c
    												where id = :line2.id];

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        System.assert( line1.c2g__Dimension1__c == line2DB.c2g__Dimension1__c, 'Dimension 1 not copied correctly to new line.' );
        System.assert( line1.c2g__Dimension2__c == line2DB.c2g__Dimension2__c, 'Dimension 2 not copied correctly to new line.' );
        System.assert( line1.c2g__Dimension3__c == line2DB.c2g__Dimension3__c, 'Dimension 3 not copied correctly to new line.' );
    }
}