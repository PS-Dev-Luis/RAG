/**
*   TestDocumentsTrigger
*   ====================
*   Test class for the setting of Customer reference field if blank when document was inserted.
*   For Sales Invoice Customer ref shall be set to Invoice Number.
*   For Cresit Note the Customer ref shall be set to the related Invoices Number if available. 
*  
*   Luis Valenzuela 17/07/2013 
*
*/
@isTest (seeAllData = true)
public with sharing class TestDocumentTriggers 
{
	
    /**
    *   TEST 1 : InsertInvoiceWithBlankCustomerReference
    *   Test SalesInvoice.Trigger after insert of documents
    *   =============================================================================
    *   start conditions    - Create a Sales invoice with a blank Customer Reference
    *   action              - insert Document
    *   end state           - The Invoice's customer Ref field set to invoice number 
    */  
    @isTest (seeAllData = true)
    public static void InsertInvoiceWithBlankCustomerReference() 
    {
		if( !TestHelper.isDevOrg() ) return;
	        
        /* ++++++++++++++++ Setup +++++++++++++++++++ */
        // Grab an account
        Account acc = [Select Id From Account limit 1];
        
        c2g.CODAAPIInvoiceTypes_7_0.Invoice invoice = new c2g.CODAAPIInvoiceTypes_7_0.Invoice();
        invoice.PrintedText1AllowEdit = false;
        invoice.PrintedText2AllowEdit = false;
        invoice.PrintedText3AllowEdit = false;
        invoice.PrintedText4AllowEdit = false;
        invoice.PrintedText5AllowEdit = false;

        c2g.CODAAPICommon.Reference d1 = new c2g.CODAAPICommon.Reference();
        d1.Id = [Select Id from c2g__codaDimension1__c limit 1].Id;
        invoice.Dimension1 = d1;

        c2g.CODAAPICommon.Reference d2 = new c2g.CODAAPICommon.Reference();
        d2.Id = [Select Id from c2g__codaDimension2__c limit 1].Id;
        invoice.Dimension2 = d2;

        c2g.CODAAPICommon.Reference d3 = new c2g.CODAAPICommon.Reference();
        d3.Id = [Select Id from c2g__codaDimension3__c limit 1].Id;
        invoice.Dimension3 = d3;  

        invoice.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        invoice.InvoiceStatus = c2g.CODAAPIInvoiceTypes_7_0.enumInvoiceStatus.InProgress;
        
        c2g.CODAAPICommon_7_0.Context context = AppContext.getApiContext();

        /* ++++++++++++++++ Action ++++++++++++++++++++++++++++ */
        invoice.CustomerReference = null;
        System.Test.startTest();
        c2g.CODAAPICommon.Reference  invRef = c2g.CODAAPISalesInvoice_7_0.CreateInvoice( context, invoice );
        System.Test.stopTest();
        
        invoice = c2g.CODAAPISalesInvoice_7_0.getInvoice(context, c2g.CODAAPICommon.getRef( invRef.id, null ));

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        System.assert( invoice.CustomerReference == invoice.name );
    }

    /**
    *   TEST 2 : InsertInvoiceWithNonBlankCustomerReference
    *   Test SalesInvoice.Trigger after insert of documents
    *   =============================================================================
    *   start conditions    - Create a Sales invoice with a non blank Customer Reference
    *   action              - insert Document
    *   end state           - The Invoice's customer Ref field NOT set to invoice number 
    */  
    @isTest (seeAllData = true)
    public static void InsertInvoiceWithNonBlankCustomerReference()
    {
		if( !TestHelper.isDevOrg() ) return;
        
        /* ++++++++++++++++ Setup +++++++++++++++++++ */
        // Grab an account
        Account acc = [Select Id From Account limit 1];
        
        c2g.CODAAPIInvoiceTypes_7_0.Invoice invoice = new c2g.CODAAPIInvoiceTypes_7_0.Invoice();
        invoice.PrintedText1AllowEdit = false;
        invoice.PrintedText2AllowEdit = false;
        invoice.PrintedText3AllowEdit = false;
        invoice.PrintedText4AllowEdit = false;
        invoice.PrintedText5AllowEdit = false;

        c2g.CODAAPICommon.Reference d1 = new c2g.CODAAPICommon.Reference();
        d1.Id = [Select Id from c2g__codaDimension1__c limit 1].Id;
        invoice.Dimension1 = d1;

        c2g.CODAAPICommon.Reference d2 = new c2g.CODAAPICommon.Reference();
        d2.Id = [Select Id from c2g__codaDimension2__c limit 1].Id;
        invoice.Dimension2 = d2;

        c2g.CODAAPICommon.Reference d3 = new c2g.CODAAPICommon.Reference();
        d3.Id = [Select Id from c2g__codaDimension3__c limit 1].Id;
        invoice.Dimension3 = d3;  

        invoice.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        invoice.InvoiceStatus = c2g.CODAAPIInvoiceTypes_7_0.enumInvoiceStatus.InProgress;
        
        c2g.CODAAPICommon_7_0.Context context = AppContext.getApiContext();

        /* ++++++++++++++++ Action ++++++++++++++++++++++++++++ */
        invoice.CustomerReference = 'TEST';
        System.Test.startTest();
        c2g.CODAAPICommon.Reference  invRef = c2g.CODAAPISalesInvoice_7_0.CreateInvoice( context, invoice );
        System.Test.stopTest();
        
        invoice = c2g.CODAAPISalesInvoice_7_0.getInvoice(context, c2g.CODAAPICommon.getRef( invRef.id, null ));

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        System.assert( invoice.CustomerReference != invoice.name );
    }


    /**
    *   TEST 3 : InsertCreditNoteWithBlankCustomerReference
    *   Test SalesCreditNote.Trigger  after insert of documents
    *   =============================================================================
    *   start conditions    - Create a Sales Credit Note with related invoice and a blank Customer Reference
    *   action              - insert Document
    *   end state           - The Credit Note's customer Ref field set to invoice number 
    */  
    @isTest (seeAllData = true)
    public static void InsertCreditNoteWithBlankCustomerReference()
    {
		if( !TestHelper.isDevOrg() ) return;
                
        /* ++++++++++++++++ Setup +++++++++++++++++++ */
        // Grab an account
        Account acc = [Select Id From Account limit 1];
        
        c2g.CODAAPIInvoiceTypes_7_0.Invoice invoice = new c2g.CODAAPIInvoiceTypes_7_0.Invoice();
        invoice.PrintedText1AllowEdit = false;
        invoice.PrintedText2AllowEdit = false;
        invoice.PrintedText3AllowEdit = false;
        invoice.PrintedText4AllowEdit = false;
        invoice.PrintedText5AllowEdit = false;

        c2g.CODAAPICommon.Reference d1 = new c2g.CODAAPICommon.Reference();
        d1.Id = [Select Id from c2g__codaDimension1__c limit 1].Id;
        invoice.Dimension1 = d1;

        c2g.CODAAPICommon.Reference d2 = new c2g.CODAAPICommon.Reference();
        d2.Id = [Select Id from c2g__codaDimension2__c limit 1].Id;
        invoice.Dimension2 = d2;

        c2g.CODAAPICommon.Reference d3 = new c2g.CODAAPICommon.Reference();
        d3.Id = [Select Id from c2g__codaDimension3__c limit 1].Id;
        invoice.Dimension3 = d3;  

        invoice.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        invoice.InvoiceStatus = c2g.CODAAPIInvoiceTypes_7_0.enumInvoiceStatus.InProgress;
        
        c2g.CODAAPICommon_7_0.Context context = AppContext.getApiContext();
        c2g.CODAAPICommon.Reference  invRef = c2g.CODAAPISalesInvoice_7_0.CreateInvoice( context, invoice );
    
        c2g.CODAAPICreditNoteTypes_7_0.CreditNote CreditNote = new c2g.CODAAPICreditNoteTypes_7_0.CreditNote();
        CreditNote.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        CreditNote.CreditNoteStatus = c2g.CODAAPICreditNoteTypes_7_0.enumCreditNoteStatus.InProgress;
        CreditNote.PrintedText1AllowEdit = false;
        CreditNote.PrintedText2AllowEdit = false;
        CreditNote.PrintedText3AllowEdit = false;
        CreditNote.PrintedText4AllowEdit = false;
        CreditNote.PrintedText5AllowEdit = false;

        CreditNote.Dimension1 = d1;

        CreditNote.Dimension2 = d2;

        CreditNote.Dimension3 = d3;  

        CreditNote.invoice = invRef;

        /* ++++++++++++++++ Action ++++++++++++++++++++++++++++ */
        CreditNote.CustomerReference = null;
        System.Test.startTest();
        c2g.CODAAPICommon.Reference  creNoteRef = c2g.CODAAPISalesCreditNote_7_0.CreateCreditNote( context, CreditNote );
        System.Test.stopTest();
        
        CreditNote = c2g.CODAAPISalesCreditNote_7_0.GetCreditNote(context, c2g.CODAAPICommon.getRef( creNoteRef.id, null ));

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        System.assert( CreditNote.CustomerReference == CreditNote.Invoice.name );
    }

    /**
    *   TEST 4 : InsertCreditNoteWithNonBlankCustomerReference
    *   Test SalesCreditNote.Trigger  after insert of documents
    *   =============================================================================
    *   start conditions    - Create a Sales Credit Note with related invoice and a blank Customer Reference
    *   action              - insert Document
    *   end state           - The Credit Note's customer Ref field NOT set to invoice number 
    */  
    @isTest (seeAllData = true)
    public static void InsertCreditNoteWithNonBlankCustomerReference()
    {
		if( !TestHelper.isDevOrg() ) return;
        
        /* ++++++++++++++++ Setup +++++++++++++++++++ */
        // Grab an account
        Account acc = [Select Id From Account limit 1];
        
        c2g.CODAAPIInvoiceTypes_7_0.Invoice invoice = new c2g.CODAAPIInvoiceTypes_7_0.Invoice();
        invoice.PrintedText1AllowEdit = false;
        invoice.PrintedText2AllowEdit = false;
        invoice.PrintedText3AllowEdit = false;
        invoice.PrintedText4AllowEdit = false;
        invoice.PrintedText5AllowEdit = false;

        c2g.CODAAPICommon.Reference d1 = new c2g.CODAAPICommon.Reference();
        d1.Id = [Select Id from c2g__codaDimension1__c limit 1].Id;
        invoice.Dimension1 = d1;

        c2g.CODAAPICommon.Reference d2 = new c2g.CODAAPICommon.Reference();
        d2.Id = [Select Id from c2g__codaDimension2__c limit 1].Id;
        invoice.Dimension2 = d2;

        c2g.CODAAPICommon.Reference d3 = new c2g.CODAAPICommon.Reference();
        d3.Id = [Select Id from c2g__codaDimension3__c limit 1].Id;
        invoice.Dimension3 = d3; 

        invoice.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        invoice.InvoiceStatus = c2g.CODAAPIInvoiceTypes_7_0.enumInvoiceStatus.InProgress;
        
        c2g.CODAAPICommon_7_0.Context context = AppContext.getApiContext();
        c2g.CODAAPICommon.Reference  invRef = c2g.CODAAPISalesInvoice_7_0.CreateInvoice( context, invoice );
    
        c2g.CODAAPICreditNoteTypes_7_0.CreditNote CreditNote = new c2g.CODAAPICreditNoteTypes_7_0.CreditNote();
        CreditNote.Account = c2g.CODAAPICommon.getRef( acc.Id, null );
        CreditNote.CreditNoteStatus = c2g.CODAAPICreditNoteTypes_7_0.enumCreditNoteStatus.InProgress;
        CreditNote.PrintedText1AllowEdit = false;
        CreditNote.PrintedText2AllowEdit = false;
        CreditNote.PrintedText3AllowEdit = false;
        CreditNote.PrintedText4AllowEdit = false;
        CreditNote.PrintedText5AllowEdit = false;

        CreditNote.Dimension1 = d1;

        CreditNote.Dimension2 = d2;

        CreditNote.Dimension3 = d3;  

        CreditNote.invoice = invRef;

        /* ++++++++++++++++ Action ++++++++++++++++++++++++++++ */
        CreditNote.CustomerReference = 'Test';
        System.Test.startTest();
        c2g.CODAAPICommon.Reference  creNoteRef = c2g.CODAAPISalesCreditNote_7_0.CreateCreditNote( context, CreditNote );
        System.Test.stopTest();
        
        CreditNote = c2g.CODAAPISalesCreditNote_7_0.GetCreditNote(context, c2g.CODAAPICommon.getRef( creNoteRef.id, null ));

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        System.assert( CreditNote.CustomerReference != CreditNote.Invoice.name );   
    }

}