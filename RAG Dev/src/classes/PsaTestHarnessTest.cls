/****************************************************************************************
Name            : PsaTestHarnessTest
Revision Log    : 2012-05-26 PR (FinancialForce) v1
                : 
Use             : This class is used to test the PSATestHarness class so that the 
                : PSATestHarness can be deployed to a prod environment
                : 
****************************************************************************************/
@isTest(SeeAllData=true)
private without sharing class PsaTestHarnessTest {

private static final Date REFERENCE_DATE = DateTime.valueOfGmt('2009-03-8 00:00:00').dateGMT();
private enum dayOfWeek {SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY}
static Date refMonDate;
static PsaTestHarness testHarness = new PsaTestHarness();

private static String SCHEDULE_PATTERN_8x5 = '8x5'; 
private static String SCHEDULE_PATTERN_10x4 = '10x4';
private static String SCHEDULE_PATTERN_0 = '0';
private static String SCHEDULE_PATTERN_1 = '1';

// The two constants are customer specific - they should be removed
static final String MILESTONE_TYPE_DEFAULT = 'Implementation';
static final String CONSULTANT_ROLENAME_DEFAULT  = 'Consultant_Test';

static void setup(){
  
  // get test harness
  
  // global setup start
  Date refMonDateStart = getMonday(Date.today());
  refMonDate = getMonday(Date.today().addDays(6));
  if(refMonDateStart.Month() != refMonDate.Month()){
    refMonDate -= 6;
  } 
}

static testMethod void validatePsaTestHarnessCalls() {
  
  setup();
  
  // -------------------------------------------
  // specific test method setup
  // -------------------------------------------
  
  // -------------------------------------------
  // start the test
  // -------------------------------------------
  Test.startTest();
  
  // -------------------------------------------
  // test the results
  // -------------------------------------------

  Account account1 = testHarness.getAccount();
  List<Account> lstAccounts = new List<Account>([
    SELECT Id,
           Name
    FROM   Account
    WHERE  Name = 'TestAccount'
  ]);
  System.assertEquals(1,lstAccounts.size(),'Account was not obtained successfully');

  Opportunity opportunity1 = testHarness.getOpportunity();
  List<Opportunity> lstOpptys = new List<Opportunity>([
    SELECT Id,
           Name
    FROM   Opportunity
    LIMIT 1
  ]);
  System.assertEquals(1,lstOpptys.size(),'Opportunity was not obtained successfully');

  User user1 = testHarness.newUserSysAdmin(true);
  List<User> lstUsers = new List<User>([
    SELECT Id
    FROM User
   WHERE Profile.Name = 'System Administrator'
    AND IsActive = true
   LIMIT 1   
  ]);
  System.assertEquals(1,lstUsers.size(),'User was not obtained successfully');

  pse__Region__c region1 = testHarness.getRegionMaster();
  List<pse__Region__c> lstRegions = new List<pse__Region__c>([
    SELECT Id
      FROM pse__Region__c
     WHERE pse__Hierarchy_Depth__c = 0
     LIMIT 1
  ]);
  System.assertEquals(1,lstRegions.size(),'Region was not obtained successfully');

  pse__Work_Calendar__c workcalendar1 = testHarness.newWorkCalender(true);
  System.assertEquals('Test Calender',workcalendar1.Name,'Work Calendar does not have the name "Test Calender"');

  Contact resource1 = testHarness.getResource(account1.Id, user1.Id, region1.Id, workcalendar1.Id);
  List<Contact> lstResources = new List<Contact>([
    SELECT Id 
      FROM Contact 
     WHERE pse__Is_Resource__c = true 
       AND pse__Is_Resource_Active__c = true 
       AND pse__Region__c = :region1.Id
       AND pse__Salesforce_User__c = :user1.Id 
     LIMIT 1 
  ]);
  System.assertEquals(1,lstResources.size(),'Resource was not obtained successfully');
  
  resource1.pse__Salesforce_User__c = null;
  update resource1;

  Contact resource2 = testHarness.newResource(true, account1.Id, user1.Id);
  lstResources.clear();
  lstResources = new List<Contact>([
    SELECT Id 
      FROM Contact 
     WHERE pse__Is_Resource__c = true 
       AND pse__Is_Resource_Active__c = true 
       AND AccountId = :account1.Id
       AND pse__Salesforce_User__c = :user1.Id 
     LIMIT 1 
  ]);
  System.assertEquals(1,lstResources.size(),'Resource was not obtained successfully');

  pse__Proj__c project1 = testHarness.newProject(true,region1.Id,TestHelper.getGlobalPracticeId().Id,true,null);
  System.assertEquals('Test Project',project1.Name,'Project does not have the name "Test Project"');

  pse__Milestone__c milestone1 = testHarness.newMilestone(true, project1.Id, 50000, refMonDate + 6);
  System.assertEquals('Test Milestone',milestone1.Name,'Milestone does not have the name "Test Milestone"');

  pse__Rate_Card__c rateCard1 = testHarness.newRateCard(true, region1.Id, null, 'Consultant Test', true, 160, 80);
  System.assertEquals(160,rateCard1.pse__Suggested_Bill_Rate__c,'Rate Card does not have a Bill Rate = 160');

  pse__Permission_Control__c permissionControl1 = testHarness.newPermissionControl(true,UserInfo.getUserId(),region1.Id);
  List<pse__Permission_Control__c> lstPCs = new List<pse__Permission_Control__c>([
    SELECT Id 
      FROM pse__Permission_Control__c 
     WHERE pse__Region__c = :region1.Id
       AND pse__User__c = :UserInfo.getUserId()
     LIMIT 1 
  ]);
  System.assertEquals(1,lstPCs.size(),'Permission Control was not obtained successfully');
  
  pse__Schedule__c schedule1 = testHarness.newSchedule(true, refMonDate, refMonDate + 6);
  System.assertEquals(refMonDate,schedule1.pse__Start_Date__c,'Schedule1 does not have the correct start date');

  pse__Schedule__c schedule2 = testHarness.newSchedule(true, refMonDate, refMonDate + 6, 1, 2, 3, 4, 5, 6, 7);
  System.assertEquals(1,schedule2.pse__Monday_Hours__c,'Schedule2 does not have Monday Hours = 1');

  pse__Schedule_Exception__c scheduleExc1 = testHarness.newScheduleException(true, schedule2.Id, refMonDate, refMonDate + 6, 1, 2, 3, 4, 5, 6, 7);
  System.assertEquals(1,scheduleExc1.pse__Monday_Hours__c,'Schedule Exception1 does not have Monday Hours = 1');

  pse__Assignment__c assignment1 = testHarness.newAssignment(true,project1.Id,resource1.Id,schedule1.Id);
  System.assertEquals(resource1.Id,assignment1.pse__Resource__c,'Assignment does not have the correct resource Id');
  
  pse__Timecard_Header__c timecardHeader1 = testHarness.newTimecardHeader(false, resource1.Id, project1.Id, null, null, refMonDate, refMonDate + 6);
  timecardHeader1.pse__Milestone__c = milestone1.Id;
  timecardHeader1.pse__Project_Methodology__c = CONSULTANT_ROLENAME_DEFAULT;
  insert timecardHeader1;
  System.assertEquals(resource1.Id,timecardHeader1.pse__Resource__c,'Timecard does not have the correct resource Id');
  
  pse__Expense_Report__c expenseReport1 = testHarness.newExpenseReport(true, project1.Id, resource1.Id);
  System.assertEquals(resource1.Id,expenseReport1.pse__Resource__c,'Expense Report does not have the correct resource Id');
  
  pse__Expense__c expense1 = testHarness.newExpense(true, expenseReport1.Id, resource1.Id, 'Airfare', 500);
  System.assertEquals(expenseReport1.Id,expense1.pse__Expense_Report__c,'Expense does not have the correct Expense Report Id');

  pse__Billing_Event__c billingEvent1 = testHarness.newBillingEvent(true, project1.Id);
  System.assertEquals(project1.Id,billingEvent1.pse__Project__c,'Billing Event does not have the correct Project Id');

  // -------------------------------------------
  // stop test
  // -------------------------------------------
  // Test.stopTest();
}

static testMethod void validatePsaTestHarnessFns() {
  
  setup();
  
  // -------------------------------------------
  // specific test method setup
  // -------------------------------------------
  
  // -------------------------------------------
  // start the test
  // -------------------------------------------
  Test.startTest();
  
  // -------------------------------------------
  // test the results
  // -------------------------------------------

/*
  Opportunity opportunity1 = testHarness.getOpportunity();
  List<Opportunity> lstOpptys = new List<Opportunity>([
    SELECT Id,
           Name
    FROM   Opportunity
    LIMIT 1
  ]);
  System.assertEquals(1,lstOpptys.size(),'Opportunity was not obtained successfully');
*/

  User user1 = testHarness.getUserSysAdmin();
  List<User> lstUsers = new List<User>([
  SELECT Id
    FROM User
   WHERE Profile.Name = 'System Administrator'
    AND IsActive = true
   LIMIT 1   
  ]);
  System.assertEquals(1,lstUsers.size(),'User was not obtained successfully');

  pse__Schedule__c schedule3 = testHarness.newSchedule(true);
  System.assertEquals(date.today(),schedule3.pse__Start_Date__c,'Schedule3 start date != today');

  pse__Schedule__c schedule4 = testHarness.newSchedule(true, refMonDate, refMonDate + 6, SCHEDULE_PATTERN_8x5);
  System.assertEquals(8,schedule4.pse__Monday_Hours__c,'Schedule4 does not have Monday Hours = 8');

  pse__Schedule__c schedule5 = testHarness.newSchedule(true, refMonDate, refMonDate + 6, SCHEDULE_PATTERN_10x4);
  System.assertEquals(10,schedule5.pse__Monday_Hours__c,'Schedule5 does not have Monday Hours = 10');

  pse__Schedule__c schedule6 = testHarness.newSchedule(true, refMonDate, refMonDate + 6, SCHEDULE_PATTERN_1);
  System.assertEquals(1,schedule6.pse__Monday_Hours__c,'Schedule6 does not have Monday Hours = 1');

  pse__Schedule__c schedule7 = testHarness.getSchedule(schedule3.Id);
  System.assertEquals(schedule3.Id,schedule7.Id,'Schedule7 start date != today');

  pse__Schedule_Exception__c scheduleExc1 = testHarness.newScheduleException(true, schedule3.Id);
  System.assertEquals(schedule3.Id,scheduleExc1.pse__Schedule__c,'Schedule Exception1 schedule ID is not correct');

  pse__Schedule_Exception__c scheduleExc2 = testHarness.newScheduleException(true, schedule4.Id, refMonDate + 1, refMonDate + 1);
  System.assertEquals(refMonDate + 1,scheduleExc2.pse__Date__c,'Schedule Exception2 start date != refMonDate + 1');

  pse__Schedule_Exception__c scheduleExc3 = testHarness.newScheduleException(true, schedule4.Id, refMonDate + 2, refMonDate + 2, SCHEDULE_PATTERN_8x5);
  System.assertEquals(8,scheduleExc3.pse__Wednesday_Hours__c,'Schedule Exception3 does not have Wednesday Hours = 8');

  pse__Schedule_Exception__c scheduleExc4 = testHarness.newScheduleException(true, schedule4.Id, refMonDate + 3, refMonDate + 3, SCHEDULE_PATTERN_10x4);
  System.assertEquals(10,scheduleExc4.pse__Thursday_Hours__c,'Schedule Exception4 does not have Thursday Hours = 10');

  pse__Schedule_Exception__c scheduleExc5 = testHarness.newScheduleException(true, schedule4.Id, refMonDate + 4, refMonDate + 4, SCHEDULE_PATTERN_1);
  System.assertEquals(1,scheduleExc5.pse__Friday_Hours__c,'Schedule Exception5 does not have Friday Hours = 1');

  // -------------------------------------------
  // stop test
  // -------------------------------------------
  // Test.stopTest();
}

private static Date getMonday(Date dt) {
  // get the number of days between the given date and the reference date (Sunday)
  Integer daysBetween = REFERENCE_DATE.daysBetween(dt);
  
  // get the remainder from dividing by the # of days in a week
  Integer remainder = Math.mod(daysBetween, 7);
  // NOTE: a negative remainder indicates a past date from the reference
  if(remainder == 0) 
    return dt.addDays(-6); // Sunday
  else if (remainder == 1 || remainder == -6)
    return dt; // MONDAY
  else if (remainder == 2 || remainder == -5)
    return dt.addDays(-1); //TUESDAY
  else if (remainder == 3 || remainder == -4)
    return dt.addDays(-2); //WEDNESDAY
  else if (remainder == 4 || remainder == -3)
    return dt.addDays(-3); //THURSDAY
  else if (remainder == 5 || remainder == -2)
    return dt.addDays(-4); //FRIDAY
  else // remainder = 6 || remainder == -1
    return dt.addDays(-5); //SATURDAY
}

} // end of class