/****************************************************************************************
Name            : TestSalesInvoicePrintCustom
Revision Log    : 2012-07-26 JT Lovell (FinancialForce): created
                : 2012-09-17 JT Lovell (FinancialForce): added support for salesinvoices
                : 
                : 2013-03-19 Luis Valenzuela : Modified for use in testing of RAG custom invoice
                : 
Use             : This class tests the PsaBilling class, triggers, and controllers
                : Includes SalesInvoice* classes
****************************************************************************************/
@isTest (seeAllData = true) 
public class TestSalesInvoicePrintCustom 
{

    // constants used for date math
    private enum dayOfWeek {SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY}
    static final Date REFERENCE_DATE_PROJECT_START = Date.newInstance(2012, 7, 2);
    static final Date REFERENCE_DATE_PROJECT_END = Date.newInstance(2012,7,8);
    static final Date REFERENCE_DATE_TIMECARD_WEEK_START = Date.newInstance(2012, 7, 2);
    static final Date REFERENCE_DATE_TIMECARD_WEEK_END = Date.newInstance(2012,7,8);
    static final Decimal TIMECARD_STANDARD_RATE = 150.0;
    
    static PsaTestHarness psaTestHarness; 
    
    static User user1;
    static Account account1;
    static Contact resource1;
    static pse__Region__c region1;
    static pse__Proj__c project1;
    static pse__Work_Calendar__c workcalendar1;
    static pse__Permission_Control__c permissionControl1;
    static pse__Permission_Control__c permissionControl2;
    static pse__Assignment__c assignment1;
    static pse__Schedule__c schedule1;
    
    static pse__Timecard_Header__c tc1;
    static pse__Timecard__c tcs1;
    static pse__Expense_Report__c er1;
    static pse__Expense__c exp1;
    static pse__Milestone__c ms1;
    static pse__Miscellaneous_Adjustment__c ma1;
    
    static pse__Billing_Event__c be1;
    static pse__Billing_Event_Item__c bei1;
    static c2g__codaInvoice__c invoice1;
    static c2g__codaInvoiceLineItem__c invoiceLineItem1;


/*
    @isTest (seeAllData = true) 
    public static void runtests()   
    {
        PsaBillingTest.testBillingTime();
        PsaBillingTest.testBillingExp();
        PsaBillingTest.testBillingMilestone();
        PsaBillingTest.testBillingMiscAdj();
    }
*/  
    
    static void setup()
    {
      
      // get custom settings
      // settings = PsaCalendarSyncSettings__c.getOrgDefaults();
      
      // get test harness
      psaTestHarness = new PsaTestHarness();
      
      // global setup start
      user1 = psaTestHarness.getUserSysAdmin();
      region1 = psaTestHarness.getRegionMaster();
      account1 = psaTestHarness.newAccount(true);
      workcalendar1 = psaTestHarness.newWorkCalender(true);
      
      // unlink any existing resource that is linked to the located user record
      List<Contact> lstContacts = [  SELECT Id,
                                            pse__Salesforce_User__c
                                      FROM  Contact
                                     WHERE  pse__Salesforce_User__c = :user1.Id];
      for(Contact c : lstContacts){
            c.pse__Salesforce_User__c = null;
      }
      update lstContacts;
      
      resource1 = psaTestHarness.newResource(false, account1.Id, user1.Id, region1.Id, workcalendar1.Id);
      resource1.email = 'testuser_PsaBillingTest@account.com';
      insert resource1;
      project1 = psaTestHarness.newProject(false,region1.Id,TestHelper.getGlobalPracticeId().Id,true,null);
      insert project1;
      
      permissionControl1 = psaTestHarness.newPermissionControl(true,user1.Id,region1.Id);
      permissionControl2 = psaTestHarness.newPermissionControl(true,UserInfo.getUserId(),region1.Id);
    }


    /**
    *   TEST 1 : testBillingTime
    *   Test Custom Sales Invoice controller for rollup of Billed Time
    *   ===============================================================
    */  
    @isTest (seeAllData = true) 
    public static void testBillingTime() 
    {
        // Test only in Dev Org
        if( !TestHelper.isDevOrg() ) return;
      
      String hashkey;
      
      /* ++++++++++++++++ SETUP +++++++++++++++++++ */
      setup();
      // Create a new schedule and assignment
      schedule1 = psaTestHarness.newSchedule(true, REFERENCE_DATE_PROJECT_START, REFERENCE_DATE_PROJECT_END, psaTestHarness.SCHEDULE_PATTERN_1);
      hashkey = String.valueOf(schedule1.Id);
      
      assignment1 = psaTestHarness.newAssignment(false, project1.Id, resource1.Id, schedule1.Id);
      assignment1.pse__Bill_Rate__c = TIMECARD_STANDARD_RATE;
    //  assignment1.PsaShowOnCalendar__c = false;
      insert assignment1;
      Log.debug('assignment created');
      
      /* ++++++++++++++++ START testBillingTime +++++++++++++++++++ */
      Test.startTest();
      
      // create a new timecard
      Decimal hrs = 1.0;//
      String notes = 'x';
      tc1 = psaTestHarness.newTimecardHeader(
        false,
        resource1.Id,
        project1.Id,
        assignment1.id,
        (Id)null,
        REFERENCE_DATE_TIMECARD_WEEK_START,
        REFERENCE_DATE_TIMECARD_WEEK_END,
        hrs,hrs,hrs,hrs,hrs,hrs,hrs,
        notes,notes,notes,notes,notes,notes,notes
      );
      tc1.pse__Billable__c = true;
      tc1.pse__Approved__c = true;
      tc1.pse__Include_In_Financials__c = true;
      tc1.pse__Submitted__c = true;
      tc1.pse__Exclude_from_Billing__c = false;
      insert tc1;
      Log.debug('Timecard header created');
      
      // find the first resulting timecard split
      List<pse__Timecard__c> lstTimecardSplits = new List<pse__Timecard__c>([
        SELECT Id,
               pse__Total_Billable_Amount__c
          FROM pse__Timecard__c
         WHERE pse__Timecard_Header__c = :tc1.Id
      ]);
      tcs1 = lstTimecardSplits[0];
      Log.debug(' Timecard split found');
      
      // create a billing event and item for the timecard
      be1 = psaTestHarness.newBillingEvent(false,project1.Id);
      be1.pse__Date__c = System.today();
      be1.pse__Skip_Sync_Check__c = true;
      insert be1;
      
      bei1 = psaTestHarness.newBillingEventItem(true,be1.Id,(String)tcs1.Id, RefData.BILL_EVENT_ITEM_CAT_TIMECARD ,project1.Id);
      Log.debug(' Billing events created');
      
      // get related record keys
      List<c2g__codaCompany__c> lstCompanies = new List<c2g__codaCompany__c>([
        SELECT Id
          FROM c2g__codaCompany__c
         WHERE name = 'Electric Hamster Corp'
         LIMIT 1
      ]);

      id compId = lstCompanies[0].id;
      
      String currencyName = 'USD';
      if(project1.CurrencyIsoCode != null){
        currencyName = project1.CurrencyIsoCode;
      }
      Log.debug(' Currency = ' + currencyName);
      
      List<c2g__codaAccountingCurrency__c> lstCurrencies = new List<c2g__codaAccountingCurrency__c>([
        SELECT Id
          FROM c2g__codaAccountingCurrency__c
         WHERE Name = :currencyName AND c2g__OwnerCompany__c = :compId 
         LIMIT 1
      ]);
      
      List<Product2> lstProducts = new List<Product2>([
        SELECT Id
          FROM Product2
         WHERE Name = :RefData.PROD_PROF_FEE_MS_NAME
           AND IsActive = true
         LIMIT 1
      ]);

    Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
    Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
    Id d3 = [Select Id from c2g__codaDimension3__c limit 1].Id;   
      
      // create a sales invoice for the timecard
      invoice1 = new c2g__codaInvoice__c(
        c2g__OwnerCompany__c = lstCompanies[0].Id,
        c2g__Account__c = account1.Id,
        c2g__InvoiceDate__c = System.today(),
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3,
        testField__c = 'hola baby',
        c2g__InvoiceCurrency__c = lstCurrencies[0].Id,
        c2g__Interval__c = 'Monthly'
      );
      insert invoice1;
      Log.debug(' Invoice created');
      
      invoiceLineItem1 = new c2g__codaInvoiceLineItem__c(
        ffpsai__BillingEventItem__c = bei1.Id,
        c2g__Invoice__c = invoice1.Id,
        c2g__Product__c = lstProducts[0].Id,
        c2g__UnitPrice__c = 1,
        c2g__Quantity__c = 1,
        c2g__TaxRate1__c = 0,
        c2g__TaxRate2__c = 0,
        c2g__TaxRate3__c = 0,
        c2g__TaxValue1__c = 0,
        c2g__TaxValue2__c = 0,
        c2g__TaxValue3__c = 0,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3        
      );
      
      invoiceLineItem1.put('ffbilling__DeriveUnitPriceFromProduct__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate1FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate2FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate3FromCode__c', false);
      
      insert invoiceLineItem1;
      Log.debug(' Invoice line item created');
      
        /* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
        // Instantiate VF page  and Controller to check for errors
        PageReference pageRef = Page.salesInvoicePrintCustom;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(invoice1);
        SalesInvoiceControllerCustom controller = new SalesInvoiceControllerCustom(sc);
        SalesInvoiceComponentsTimeController timeController = new SalesInvoiceComponentsTimeController();
        SalesInvoiceComponentsSummaryController sumController = new SalesInvoiceComponentsSummaryController();
        timeController.setTimecardBillEvents( controller.timeCardBillingEventsCustom);
        sumController.setOriginInvoicelines( controller.invoiceLinesCustom );
        
        /* ++++++++++++++++ STOP testBillingTime +++++++++++++++++++ */
        Test.stopTest();      
                
        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        pse__Timecard__c[] timeCardList = timeController.timeCards;
        boolean tcPresentOnSummary = false;
        for (c2g__codaInvoiceLineItem__c sumInvLin : sumController.summaryInvoiceLines)
        {
            if ( sumInvLin.c2g__LineDescription__c == RefData.INVOICE_CATEGORY_PROF_FEES )
            {
                tcPresentOnSummary = true;
            }
        }
        System.assert(tcPresentOnSummary );
        System.assert( timeCardList[0].pse__Total_Hours__c  == 7);
    }


    /**
    *   TEST 2 : testBillingExp
    *   Test Custom Sales Invoice controller for rollup of Billed Expenses
    *   ==================================================================
    */  
    @isTest (seeAllData = true) 
    public static void testBillingExp() 
    {
        // Test only in Dev Org
        if( !TestHelper.isDevOrg() ) return;
    Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
    Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
    Id d3 = [Select Id from c2g__codaDimension3__c limit 1].Id;       
      String hashkey;
      
      /* ++++++++++++++++ SETUP +++++++++++++++++++ */
      setup();
  
      // Create a new schedule and assignment
      schedule1 = psaTestHarness.newSchedule(true, REFERENCE_DATE_PROJECT_START, REFERENCE_DATE_PROJECT_END, psaTestHarness.SCHEDULE_PATTERN_1);
      hashkey = String.valueOf(schedule1.Id);
      
      assignment1 = psaTestHarness.newAssignment(false, project1.Id, resource1.Id, schedule1.Id);
      assignment1.pse__Bill_Rate__c = TIMECARD_STANDARD_RATE;
      //  assignment1.PsaShowOnCalendar__c = false;
      insert assignment1;
      Log.debug('assignment created');
      
      /* ++++++++++++++++ START testBillingExp +++++++++++++++++++ */
      Test.startTest();
      
      // create a new expense report
      er1 = psaTestHarness.newExpenseReport(false,project1.Id,resource1.Id);
      er1.pse__Assignment__c = assignment1.Id;
      er1.pse__Billable__c = true;
      er1.ffpsai__ExpenseGLACode__c = [Select id from c2g__codaGeneralLedgerAccount__c  limit 1].id;
      insert er1;
      Log.debug(' Expense report created');
      
      // create expense item
      exp1 = psaTestHarness.newExpense(true,er1.Id,resource1.Id,'Tolls',100.0);
      exp1.ffpsai__ExpenseGLACode__c = [Select id from c2g__codaGeneralLedgerAccount__c  limit 1].id;
      update exp1;
      Log.debug(' Expense item created');
      
      // update expense report to approved
      er1.pse__Status__c = 'Approved';
      er1.pse__Approved__c = true;
      er1.pse__Include_In_Financials__c = true;
      er1.pse__Submitted__c = true;
      er1.pse__Exclude_from_Billing__c = false;
      update er1;
      Log.debug(' Expense report updated');
      
      // create a billing event and item for the timecard
      be1 = psaTestHarness.newBillingEvent(false,project1.Id);
      be1.pse__Date__c = System.today();
      be1.pse__Skip_Sync_Check__c = true;
      insert be1;
      
      bei1 = psaTestHarness.newBillingEventItem(true,be1.Id,(String)exp1.Id, RefData.BILL_EVENT_ITEM_CAT_EXPENSE ,project1.Id);
      Log.debug(' Billing events created');
      
      // get related record keys
      List<c2g__codaCompany__c> lstCompanies = new List<c2g__codaCompany__c>([
        SELECT Id
          FROM c2g__codaCompany__c
         WHERE name = 'Electric Hamster Corp'
         LIMIT 1
      ]);
      
      id compId = lstCompanies[0].id;
      
      String currencyName = 'USD';
      if(project1.CurrencyIsoCode != null){
        currencyName = project1.CurrencyIsoCode;
      }
      Log.debug(' Currency = ' + currencyName);
      
      List<c2g__codaAccountingCurrency__c> lstCurrencies = new List<c2g__codaAccountingCurrency__c>([
        SELECT Id
          FROM c2g__codaAccountingCurrency__c
         WHERE Name = :currencyName AND c2g__OwnerCompany__c = :compId 
         LIMIT 1
      ]);
      
      List<Product2> lstProducts = new List<Product2>([
        SELECT Id
          FROM Product2
         WHERE Name = :RefData.PROD_PROF_FEE_MS_NAME
           AND IsActive = true
         LIMIT 1
      ]);
      
      // create a sales invoice for the timecard
      invoice1 = new c2g__codaInvoice__c(
        c2g__OwnerCompany__c = lstCompanies[0].Id,
        c2g__Account__c = account1.Id,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3,        
        c2g__InvoiceDate__c = System.today(),
        c2g__InvoiceCurrency__c = lstCurrencies[0].Id,
        c2g__Interval__c = 'Monthly'
      );
      insert invoice1;
      Log.debug(' Invoice created');
      
      invoiceLineItem1 = new c2g__codaInvoiceLineItem__c(
        ffpsai__BillingEventItem__c = bei1.Id,
        c2g__Invoice__c = invoice1.Id,
        c2g__Product__c = lstProducts[0].Id,
        c2g__UnitPrice__c = 1,
        c2g__Quantity__c = 1,
        c2g__TaxRate1__c = 0,
        c2g__TaxRate2__c = 0,
        c2g__TaxRate3__c = 0,
        c2g__TaxValue1__c = 0,
        c2g__TaxValue2__c = 0,
        c2g__TaxValue3__c = 0,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3        
      );
      
      invoiceLineItem1.put('ffbilling__DeriveUnitPriceFromProduct__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate1FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate2FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate3FromCode__c', false);
      
      insert invoiceLineItem1;
      Log.debug(' Invoice line item created');
      
        /* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
        // Instantiate VF page  and Controller to check for errors
        PageReference pageRef = Page.salesInvoicePrintCustom;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(invoice1);
        SalesInvoiceControllerCustom controller = new SalesInvoiceControllerCustom(sc);
        SalesInvoiceComponentsExpController expController = new SalesInvoiceComponentsExpController();
        SalesInvoiceComponentsSummaryController sumController = new SalesInvoiceComponentsSummaryController();
        expController.setExpenseBillEvents( controller.expensesBillingEventsCustom);
        sumController.setOriginInvoicelines( controller.invoiceLinesCustom );
        
        /* ++++++++++++++++ STOP testBillingExp +++++++++++++++++++ */
        Test.stopTest();

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        SalesInvoiceComponentsExpController.wrappedExpenseReport[] expRep = expController.expReportsSorted;
        boolean expPresentOnSummary = false;
        for (c2g__codaInvoiceLineItem__c sumInvLin : sumController.summaryInvoiceLines)
        {
            if ( sumInvLin.c2g__LineDescription__c == RefData.INVOICE_CATEGORY_EXPENSE )
            {
                expPresentOnSummary = true;
            }
        }
        // Assert that the exp inv line is present and has correct total
        // System.assert( expPresentOnSummary );
        // System.assert( expRep[0].invoiceAmount == exp1.pse__Amount__c );
     }


    /**
    *   TEST 3 : testBillingMilestone
    *   Test Custom Sales Invoice controller for rollup of Billed Milestones
    *   ====================================================================
    */  
    @isTest (seeAllData = true) 
    public static void testBillingMilestone() 
    {
        // Test only in Dev Org
        if( !TestHelper.isDevOrg() ) return;
    Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
    Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
    Id d3 = [Select Id from c2g__codaDimension3__c limit 1].Id;         
      String hashkey;
    
     /* ++++++++++++++++ SETUP +++++++++++++++++++ */
      setup();
   
      // Create a new schedule and assignment
      schedule1 = psaTestHarness.newSchedule(true, REFERENCE_DATE_PROJECT_START, REFERENCE_DATE_PROJECT_END, psaTestHarness.SCHEDULE_PATTERN_1);
      hashkey = String.valueOf(schedule1.Id);
      
      assignment1 = psaTestHarness.newAssignment(false, project1.Id, resource1.Id, schedule1.Id);
      assignment1.pse__Bill_Rate__c = TIMECARD_STANDARD_RATE;
      //  assignment1.PsaShowOnCalendar__c = false;
      insert assignment1;
      Log.debug('assignment created');
      
      /* ++++++++++++++++ START testBillingMilestone +++++++++++++++++++ */
      Test.startTest();
      
      // create a new milestone
      ms1 = psaTestHarness.newMilestone(false,project1.Id,100.0,System.Today());
      ms1.pse__Approved__c = true;
      ms1.pse__Actual_Date__c = System.Today();
      ms1.pse__Status__c = 'Approved';
      ms1.pse__Include_In_Financials__c = true;
      insert ms1;
      Log.debug('milestone created found');
      
      // create a billing event and item for the timecard
      be1 = psaTestHarness.newBillingEvent(false,project1.Id);
      be1.pse__Date__c = System.today();
      be1.pse__Skip_Sync_Check__c = true;
      insert be1;
      
      bei1 = psaTestHarness.newBillingEventItem(true,be1.Id,(String)ms1.Id, RefData.BILL_EVENT_ITEM_CAT_MILESTONE ,project1.Id);
      Log.debug('billing events created');
      
      // get related record keys
      List<c2g__codaCompany__c> lstCompanies = new List<c2g__codaCompany__c>([
        SELECT Id
          FROM c2g__codaCompany__c
         WHERE name = 'Electric Hamster Corp'          
         LIMIT 1
      ]);
      
      id compId = lstCompanies[0].id;

      String currencyName = 'USD';
      if(project1.CurrencyIsoCode != null){
        currencyName = project1.CurrencyIsoCode;
      }
      Log.debug('Currency = ' + currencyName);
      
      List<c2g__codaAccountingCurrency__c> lstCurrencies = new List<c2g__codaAccountingCurrency__c>([
        SELECT Id
          FROM c2g__codaAccountingCurrency__c
         WHERE Name = :currencyName AND c2g__OwnerCompany__c = :compId 
         LIMIT 1
      ]);
      
      List<Product2> lstProducts = new List<Product2>([
        SELECT Id
          FROM Product2
         WHERE Name = :RefData.PROD_PROF_FEE_MS_NAME
           AND IsActive = true
         LIMIT 1
      ]);
      
      // create a sales invoice for the timecard
      invoice1 = new c2g__codaInvoice__c(
        c2g__OwnerCompany__c = lstCompanies[0].Id,
        c2g__Account__c = account1.Id,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3,        
        c2g__InvoiceDate__c = System.today(),
        c2g__InvoiceCurrency__c = lstCurrencies[0].Id,
        c2g__Interval__c = 'Monthly'
      );
      insert invoice1;
      Log.debug('invoice created');
      
      invoiceLineItem1 = new c2g__codaInvoiceLineItem__c(
        ffpsai__BillingEventItem__c = bei1.Id,
        c2g__Invoice__c = invoice1.Id,
        c2g__Product__c = lstProducts[0].Id,
        c2g__UnitPrice__c = 1,
        c2g__Quantity__c = 1,
        c2g__TaxRate1__c = 0,
        c2g__TaxRate2__c = 0,
        c2g__TaxRate3__c = 0,
        c2g__TaxValue1__c = 0,
        c2g__TaxValue2__c = 0,
        c2g__TaxValue3__c = 0,
                c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3
      );
      
        invoiceLineItem1.put('ffbilling__DeriveUnitPriceFromProduct__c', false);
        invoiceLineItem1.put('ffbilling__DeriveTaxRate1FromCode__c', false);
        invoiceLineItem1.put('ffbilling__DeriveTaxRate2FromCode__c', false);
        invoiceLineItem1.put('ffbilling__DeriveTaxRate3FromCode__c', false);
        
      insert invoiceLineItem1;
      Log.debug('invoice line item created');
      
        /* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
        // Instantiate VF page  and Controller to check for errors
        PageReference pageRef = Page.salesInvoicePrintCustom;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(invoice1);
        SalesInvoiceControllerCustom controller = new SalesInvoiceControllerCustom(sc);
        SalesInvoiceComponentsMSController msController = new SalesInvoiceComponentsMSController();
        SalesInvoiceComponentsSummaryController sumController = new SalesInvoiceComponentsSummaryController();
    
        msController.setMileStoneBillEvents( controller.mileStoneBillingEventsCustom );
        sumController.setOriginInvoicelines( controller.invoiceLinesCustom );

        /* ++++++++++++++++ STOP testBillingMilestone +++++++++++++++++++ */
        Test.stopTest();

        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        pse__Milestone__c[] milestoneList = msController.milestones;
        boolean msPresentOnSummary = false;
        for (c2g__codaInvoiceLineItem__c sumInvLin : sumController.summaryInvoiceLines)
        {
            if ( sumInvLin.c2g__LineDescription__c == RefData.INVOICE_CATEGORY_MILESTONE )
            {
                msPresentOnSummary = true;
            }
        }
        // System.assert(msPresentOnSummary );
        // System.assert( milestoneList[0].pse__Milestone_Amount__c == ms1.pse__Milestone_Amount__c);
    }

    
    /**
    *   TEST 4 : testBillingMiscAdj
    *   Test Custom Sales Invoice controller for rollup of Billed Misc Ajds
    *   ====================================================================
    */  
    @isTest (seeAllData = true) 
    public static void testBillingMiscAdj() 
    {
        // Test only in Dev Org
        if( !TestHelper.isDevOrg() ) return;
    Id d1 = [Select Id from c2g__codaDimension1__c limit 1].Id;
    Id d2 = [Select Id from c2g__codaDimension2__c limit 1].Id;
    Id d3 = [Select Id from c2g__codaDimension3__c limit 1].Id;         
      String hashkey;
      /* ++++++++++++++++ SETUP +++++++++++++++++++ */
      setup();
      
      // Create a new schedule and assignment
      schedule1 = psaTestHarness.newSchedule(true, REFERENCE_DATE_PROJECT_START, REFERENCE_DATE_PROJECT_END, psaTestHarness.SCHEDULE_PATTERN_1);
      hashkey = String.valueOf(schedule1.Id);
      
      assignment1 = psaTestHarness.newAssignment(false, project1.Id, resource1.Id, schedule1.Id);
      assignment1.pse__Bill_Rate__c = TIMECARD_STANDARD_RATE;
//    assignment1.PsaShowOnCalendar__c = false;
      insert assignment1;
      Log.debug(' Assignment created');
      
      /* ++++++++++++++++ START testBillingMiscAdj +++++++++++++++++++ */
      Test.startTest();
      
      // get related record keys
      List<c2g__codaCompany__c> lstCompanies = new List<c2g__codaCompany__c>([
        SELECT Id
          FROM c2g__codaCompany__c
         WHERE name = 'Electric Hamster Corp'
         LIMIT 1
      ]);
      
      id compId = lstCompanies[0].id;

      String currencyName = 'USD';
      if(project1.CurrencyIsoCode != null){
        currencyName = project1.CurrencyIsoCode;
      }
      Log.debug(' Currency = ' + currencyName);
      
      List<c2g__codaAccountingCurrency__c> lstCurrencies = new List<c2g__codaAccountingCurrency__c>([
        SELECT Id
          FROM c2g__codaAccountingCurrency__c
         WHERE Name = :currencyName AND c2g__OwnerCompany__c = :compId 
         LIMIT 1
      ]);
      
      List<Product2> lstProducts = new List<Product2>([
        SELECT Id,
               c2g__CODASalesRevenueAccount__c
          FROM Product2
         WHERE Name = :RefData.PROD_PROF_FEE_MS_NAME
           AND IsActive = true
         LIMIT 1
      ]);
      
      // create a new milestone
      ma1 = new pse__Miscellaneous_Adjustment__c(
        pse__Project__c = project1.Id,
        pse__Amount__c = 100.0,
        pse__Effective_Date__c = System.Today(),
        pse__Transaction_Category__c = 'Ready-to-Bill Revenue',
        pse__Approved__c = true,
        pse__Include_In_Financials__c = true,
        pse__Status__c = 'Approved',
        ffpsai__ServicesProduct__c = lstProducts[0].Id,
        ffpsai__BalancingGLACode__c = lstProducts[0].c2g__CODASalesRevenueAccount__c,
        ffpsai__MiscAdjGLACode__c = lstProducts[0].c2g__CODASalesRevenueAccount__c,
        ffpsai__MiscellaneousAdjustmentCurrency__c = lstCurrencies[0].Id,
        ffpsai__OwnerCompany__c = lstCompanies[0].Id
      );
      insert ma1;
      Log.debug(' Misc adj created found');
      
      // create a billing event and item for the timecard
      be1 = psaTestHarness.newBillingEvent(false,project1.Id);
      be1.pse__Date__c = System.today();
      be1.pse__Skip_Sync_Check__c = true;
      insert be1;
      
      bei1 = psaTestHarness.newBillingEventItem(true,be1.Id,(String)ma1.Id, RefData.BILL_EVENT_ITEM_CAT_MISCADJ,project1.Id);
      Log.debug(' Billing events created');//                       Miscellaneous Adjustment
      
      // create a sales invoice for the timecard
      invoice1 = new c2g__codaInvoice__c(
        c2g__OwnerCompany__c = lstCompanies[0].Id,
        c2g__Account__c = account1.Id,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3,        
        c2g__InvoiceDate__c = System.today(),
        c2g__InvoiceCurrency__c = lstCurrencies[0].Id,
        c2g__Interval__c = 'Monthly'
      );
      insert invoice1;
      Log.debug(' Invoice created');
      
      invoiceLineItem1 = new c2g__codaInvoiceLineItem__c(
        ffpsai__BillingEventItem__c = bei1.Id,
        c2g__Invoice__c = invoice1.Id,
        c2g__Product__c = lstProducts[0].Id,
        c2g__UnitPrice__c = 1,
        c2g__Quantity__c = 1,
        c2g__TaxRate1__c = 0,
        c2g__TaxRate2__c = 0,
        c2g__TaxRate3__c = 0,
        c2g__TaxValue1__c = 0,
        c2g__TaxValue2__c = 0,
        c2g__TaxValue3__c = 0,
        c2g__dimension1__c = d1,
        c2g__dimension2__c = d2,
        c2g__dimension3__c = d3
      );
             
      invoiceLineItem1.put('ffbilling__DeriveUnitPriceFromProduct__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate1FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate2FromCode__c', false);
      invoiceLineItem1.put('ffbilling__DeriveTaxRate3FromCode__c', false);
      
      insert invoiceLineItem1;
      Log.debug(' Invoice line item created');
      
       /* ++++++++++++++++ Call Controllers ++++++++++++++++++++++++++++ */
        // Instantiate VF page  and Controller to check for errors
        PageReference pageRef = Page.salesInvoicePrintCustom;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(invoice1);
        SalesInvoiceControllerCustom controller = new SalesInvoiceControllerCustom(sc);
        SalesInvoiceComponentsMaController miscAdjController = new SalesInvoiceComponentsMaController();
        SalesInvoiceComponentsSummaryController sumController = new SalesInvoiceComponentsSummaryController();
        miscAdjController.setMiscAdjBillEvents( controller.miscAdjsBillingEventsCustom );
        sumController.setOriginInvoicelines( controller.invoiceLinesCustom );
        pse__Miscellaneous_Adjustment__c[] miscAdjs = miscAdjController.miscAdjustments;

        /* ++++++++++++++++ STOP testBillingMiscAdj +++++++++++++++++++ */
        Test.stopTest();
        
        /* ++++++++++++++++ Assertions ++++++++++++++++++++++++++++ */
        boolean miscAdjPresentOnSummary = false;
        for (c2g__codaInvoiceLineItem__c sumInvLin : sumController.summaryInvoiceLines)
        {
            if ( sumInvLin.c2g__LineDescription__c == RefData.INVOICE_CATEGORY_MISCADJ )
            {
                miscAdjPresentOnSummary = true;
            }
        }
        // System.assert( miscAdjPresentOnSummary );
        // System.assert( miscAdjs[0].pse__Amount__c == ma1.pse__Amount__c );
    }
    
} // end of class