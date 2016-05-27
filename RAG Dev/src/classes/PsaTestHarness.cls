/****************************************************************************************
Name            : PsaTestHarness
Revision Log    : 2012-02-29 JT (FinancialForce) v1
                : 2012-04-16 JT (FinancialForce) v2 - added timecard methods
                : 2012-04024 PR (FinancialForce) v3 - added Expenses and Billing Events
                : 2012-05025 PR (FinancialForce) v4 - added Rate Cards
                : 
Use             : This class is called from other test classes to make test class 
                : writing more consistent
                : 
****************************************************************************************/
@isTest(SeeAllData=true)
public without sharing class PsaTestHarness {

// *************************************************************************************************
// GLOBALS and CONSTANTS
// *************************************************************************************************

// general constants
public final String CURRENCY_DEFAULT = 'USD';
public final String COUNTRY_DEFAULT = 'US';
public final Id NULL_ID = null;
public final Decimal NULL_DECIMAL = null;
public final String NULL_STRING = null;

// standard object constants
public final String USER_EMAIL_ENCODING_KEY_DEFAULT = 'ISO-8859-1';
public final String USER_LANGUAGE_LOCALE_KEY_DEFAULT = 'en_US';
public final String USER_LOCALE_SID_KEY_DEFAULT = 'en_US';
public final String USER_TIME_ZONE_SID_KEY_DEFAULT= 'America/New_York';
public final String OPP_STAGE_NAME_CLOSED_WON = 'Closed Won';
public final String OPP_STAGE_NAME_CLOSED_LOST = 'Closed Lost';

// psa organization constants
public final String RESOURCE_RECORD_TYPE_NAME = ''; // leave empty if not using record types on contact for resources
public final String RESOURCE_ROLE_DEFAULT = 'Consultant';
public final Decimal RESOURCE_BILL_RATE_DEFAULT = 100.0;
public final Decimal RESOURCE_COST_RATE_DEFAULT = 80.0;

// psa project constants
public final String TIMECARD_STATUS_SAVED = 'Saved';
public final String TIMECARD_STATUS_SUBMITTED = 'Submitted';
public final String TIMECARD_STATUS_APPROVED = 'Approved';
public final String TIMECARD_STATUS_REJECTED = 'Rejected';

// psa schedule patterns
public final String SCHEDULE_PATTERN_8x5 = '8x5';
public final String SCHEDULE_PATTERN_10x4 = '10x4';
public final String SCHEDULE_PATTERN_0 = '0';
public final String SCHEDULE_PATTERN_1 = '1';

public final String EXPENSE_REPORT_STATUS_DRAFT = 'Draft';
public final String EXPENSE_REPORT_STATUS_SUBMITTED = 'Submitted';
public final String EXPENSE_REPORT_STATUS_APPROVED = 'Approved';
public final String EXPENSE_REPORT_STATUS_REJECTED = 'Rejected';
public final String EXPENSE_REPORT_DESC_DRAFT = 'Description';

public final Decimal EXPENSE_AMOUNT_DEFAULT = 100.0;
public final String EXPENSE_EXPENSE_TYPE_DEFAULT = 'Taxi';

public final Decimal TIMECARD_HOURS_PER_DAY_DEFAULT = 8;
static final String CONSULTANT_ROLENAME_DEFAULT = 'Consultant';

// global variables
public Integer nameIndex = 0; // used to ensure uniqueness for new records
public Map<String,Id> mapRecordTypeIds = new Map<String,Id>();

// *************************************************************************************************
// STANDARD OBJECT METHODS
// *************************************************************************************************

// ============================================================================
// Account 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Account getAccount(){
  List<Account> lstAccounts = new List<Account>([
    SELECT Id
      FROM Account
     WHERE Name = 'TestAccount'
     LIMIT 1
  ]);
  
  if(lstAccounts.size() == 1){
    return lstAccounts[0];
  } else {
    return newAccount(true);
  }
}


public Account newAccount(Boolean isInsert){
  Account rec = new Account(
    Name = 'TestAccount',
    BillingCity = 'New York',
    BillingStreet = '100 Main st',
    BillingState = 'NY',
    BillingPostalCode = '11111',
    BillingCountry = COUNTRY_DEFAULT
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// ============================================================================
// Contact 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Contact getResource(
  Id accountId, 
  Id userId,
  Id regionId, 
  Id workCalendarId
){
  
  // filter for record type if used
  List<Contact> lstContacts = new List<Contact>([
    SELECT Id 
      FROM Contact 
     WHERE pse__Is_Resource__c = true 
       AND pse__Is_Resource_Active__c = true 
       AND pse__Region__c = :regionId
       AND pse__Salesforce_User__c = :userId 
     LIMIT 1 
  ]);
  
  if(lstContacts.size() == 1){
    return lstContacts[0];
  } else {
    return newResource(true, accountId, userId, regionId, workCalendarId);
  }
}


public Contact newResource(
  Boolean isInsert, 
  Id accountId,
  Id userId
  ){
  
  return newResource(
    isInsert,
    accountId,
    userId,
    NULL_ID,
    NULL_ID
  );
}


public Contact newResource(
  Boolean isInsert, 
  Id accountId, 
  Id userId,
  Id regionId, 
  Id workCalendarId
){
  Contact rec = new Contact(
    AccountId = accountId,
    Email = 'Test_' + nameIndex + '@company.com',
    LastName = 'Test_' + (nameIndex++),
    pse__Region__c = regionId,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Is_Resource_Active__c = true,
    pse__Is_Resource__c = true,
    pse__Resource_Role__c = RESOURCE_ROLE_DEFAULT,
    pse__Default_Cost_Rate__c = RESOURCE_COST_RATE_DEFAULT,
    pse__Work_Calendar__c = workCalendarId,
    pse__Salesforce_User__c = userId
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// ============================================================================
// Opportunity 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public Opportunity getOpportunity(){
  
  List<Opportunity> lstOpportunity = new List<Opportunity>([
    SELECT Id 
      FROM Opportunity 
     LIMIT 1 
  ]);
  
  if(lstOpportunity.size() == 1){
    return lstOpportunity[0];
  } else {
    return newOpportunity(true);
  }
}


public Opportunity newOpportunity(
  Boolean isInsert
  ){
  
  return newOpportunity(
    isInsert,
    getAccount().Id,
    (String)null,
    (Date)null
  );
}

public Opportunity newOpportunity(
  Boolean isInsert,
  Id accountId
  ){
  
  return newOpportunity(
    isInsert,
    accountId,
    (String)null,
    (Date)null
  );
}

public Opportunity newOpportunity(
  Boolean isInsert, 
  Id accountId,
  String stageName,
  Date closeDate
  ){
  
  // set defaults
  if(stageName == null || stageName == ''){
    stageName = OPP_STAGE_NAME_CLOSED_WON;
  }
  if(closeDate == null){
    closeDate = Date.today();
  }
  
  Opportunity rec = new Opportunity(
    Name = 'TestOpp',
    AccountId = accountId,
    StageName = stageName,
    CloseDate = closeDate,
    CurrencyIsoCode = CURRENCY_DEFAULT
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}







// ============================================================================
// User 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public User getUserSysAdmin(){
  
  List<User> lstUsers = new List<User>([
  SELECT Id
    FROM User
   WHERE Profile.Name = 'System Administrator'
    AND IsActive = true
   LIMIT 1   
  ]);
  
  if(lstUsers.size() > 0){
    return lstUsers[0];
  } else {
    return newUserSysAdmin(true);
  }
}


public User newUserSysAdmin(Boolean isInsert){
  
  Integer i = (integer)(Math.random()*1000);
  
  List<Profile> lstProfiles = new List<Profile>([
    SELECT Id 
      FROM Profile 
     WHERE Name = 'System Administrator' 
    LIMIT 1
  ]);
  if(lstProfiles.size() == 0) {
    System.debug('ERROR: no system admin profile found');
    return null;
  }
  
  User rec = new User(
    firstName = 'test' + i,
    LastName = 'test' + i,
    Alias = 'tst' + i,
    Email = 'test' + i + '.test@test.com',
    UserName='test'+ Math.random().format()+i+'user1@test.com',
    EmailEncodingKey = USER_EMAIL_ENCODING_KEY_DEFAULT,
    LanguageLocaleKey = USER_LANGUAGE_LOCALE_KEY_DEFAULT,
    TimeZoneSidKey = USER_TIME_ZONE_SID_KEY_DEFAULT,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    LocaleSidKey = USER_LOCALE_SID_KEY_DEFAULT,
    ProfileId = lstProfiles[0].Id,
    IsActive=true
    );
  
  rec.CommunityNickname = rec.firstname + '_' + datetime.now() + rec.lastName;
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// *************************************************************************************************
// PSA ORGANIZATION OBJECT METHODS
// *************************************************************************************************

// ============================================================================
// Permission Controls 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Permission_Control__c newPermissionControl(
  Boolean isInsert,
  Id userId,
  Id regionId
){
  return newPermissionControl(
    isInsert,
    userId,
    regionId,
    NULL_ID,
    NULL_ID,
    NULL_ID,
    NULL_ID,
    true
  );
}

public pse__Permission_Control__c newPermissionControl(
  Boolean isInsert,
  Id userId,
  Id regionId,
  Id practiceId,
  Id groupId,
  Id projectId,
  Id resourceId,
  Boolean isCascading
){
  
  pse__Permission_Control__c rec = new pse__Permission_Control__c(
    pse__User__c = userId,
    pse__Resource__c = resourceId,
    pse__Region__c = regionId,
    pse__Practice__c = practiceId,
    pse__Group__c = groupId,
    pse__Project__c = projectId,
    pse__Cascading_Permission__c = isCascading,
    pse__Timecard_Ops_Edit__c = true,
    pse__Timecard_Entry__c = true,
    pse__Staffing__c = true,
    pse__Skills_And_Certifications_View__c = true,
    pse__Skills_And_Certifications_Entry__c = true, 
    pse__Resource_Request_Entry__c = true,
    pse__Invoicing__c = true,
    pse__Forecast_View__c = true,
    pse__Forecast_Edit__c = true,
    pse__Expense_Ops_Edit__c = true,
    pse__Expense_Entry__c = true,
    pse__Billing__c = true
  );
  
  if(isInsert){
    insert rec;
  }
  
  return rec;
}


// ============================================================================
// Region 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Region__c getRegionMaster(){
  List<pse__Region__c> lstRecs = new List<pse__Region__c>([
    SELECT Id
      FROM pse__Region__c
     WHERE pse__Hierarchy_Depth__c = 0
     LIMIT 1
  ]);
  
  if(lstRecs.size() == 1){
    return lstRecs[0];
  } else {
    return newRegionMaster(true);
  }
}


public pse__Region__c newRegionMaster(Boolean isInsert){
  pse__Region__c rec = new pse__Region__c(
    Name = 'Region1'
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}




// ============================================================================
// Work Calendar 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Work_Calendar__c newWorkCalender(Boolean isInsert){
  pse__Work_Calendar__c rec = new pse__Work_Calendar__c(
    Name ='Test Calender',
    pse__Week_Start_Day__c = 'Sunday',
    pse__Sunday_Hours__c = 0.0,
    pse__Monday_Hours__c = 8.0,
    pse__Tuesday_Hours__c = 8.0,
    pse__Wednesday_Hours__c = 8.0,
    pse__Thursday_Hours__c =8.0,
    pse__Friday_Hours__c = 8.0,
    pse__Saturday_Hours__c = 0.0
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


// *************************************************************************************************
// PSA PROJECT OBJECT METHODS
// *************************************************************************************************


// ============================================================================
// Project 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Proj__c newProject(
  Boolean isInsert,
  Id regionId,
  Id practiceId, 
  Boolean isBillable, 
  String billingType
){
  
  pse__Proj__c project = new pse__Proj__c(
    Name= 'Test Project',
    pse__Region__c = regionId,
    pse__Practice__c = practiceId, 
    pse__Is_Billable__c  = IsBillable, 
    pse__Closed_for_Time_Entry__c = false,
    pse__Closed_for_Expense_Entry__c = false,
    pse__Stage__c = 'In Progress',
    pse__Is_Active__c = true,
    pse__Allow_Timecards_Without_Assignment__c=true,
    pse__Allow_Expenses_Without_Assignment__c=true,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Project_Type__c = 'Customer Project',
    pse__Billing_Type__c = billingType,
    pse__Expense_Budget__c = 1000,
    pse__Start_Date__c = Date.today(),
    pse__End_Date__c = Date.today().addDays(1)
  );
  if(isInsert){
    insert project;
  }
  return project;
}


// ============================================================================
// Milestone 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Milestone__c newMilestone(
  Boolean isInsert,
  Id projectId,
  Decimal milestoneAmount, 
  Date targetDate
){
  
  pse__Milestone__c rec = new pse__Milestone__c(
    Name= 'Test Milestone',
    pse__Project__c = projectId,
    CurrencyIsoCode = CURRENCY_DEFAULT,
    pse__Milestone_Amount__c = milestoneAmount,
    pse__Target_Date__c = targetDate
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}


// ============================================================================
// Assignment and Schedules
// 
// Methods for retrieving and creating records of this type
// ============================================================================

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate
){
  
  // build a schedule 
  pse__Schedule__c s = new pse__Schedule__c(
    pse__Start_Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Monday_Hours__c = 0, 
    pse__Tuesday_Hours__c = 0,
    pse__Wednesday_Hours__c = 0,
    pse__Thursday_Hours__c = 0,
    pse__Friday_Hours__c = 0,
    pse__Saturday_Hours__c = 0,
    pse__Sunday_Hours__c = 0
  );
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert
){
  
  // build a schedule 
  pse__Schedule__c s = newSchedule(false, Date.today(), Date.today());
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate,
  String schedulePattern
){
  
  pse__Schedule__c s = newSchedule(false, startDate, endDate);
  
  if(schedulePattern == null || 
     schedulePattern == '' || 
     schedulePattern == SCHEDULE_PATTERN_0 ){
    // do nothing - pattern of 0's
  } else if (schedulePattern == SCHEDULE_PATTERN_8x5){
    s.pse__Monday_Hours__c    = 8;
    s.pse__Tuesday_Hours__c   = 8;
    s.pse__Wednesday_Hours__c = 8;
    s.pse__Thursday_Hours__c  = 8;
    s.pse__Friday_Hours__c    = 8;
  } else if (schedulePattern == SCHEDULE_PATTERN_10x4){
    s.pse__Monday_Hours__c    = 10;
    s.pse__Tuesday_Hours__c   = 10;
    s.pse__Wednesday_Hours__c = 10;
    s.pse__Thursday_Hours__c  = 10;
    s.pse__Friday_Hours__c    = 0;
  } else if (schedulePattern == SCHEDULE_PATTERN_1){
    s.pse__Monday_Hours__c    = 1;
    s.pse__Tuesday_Hours__c   = 1;
    s.pse__Wednesday_Hours__c = 1;
    s.pse__Thursday_Hours__c  = 1;
    s.pse__Friday_Hours__c    = 1;
    s.pse__Saturday_Hours__c    = 1;
    s.pse__Sunday_Hours__c    = 1;
  }
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule__c newSchedule(
  Boolean isInsert, 
  Date startDate,
  Date endDate,
  Decimal mondayHours,
  Decimal tuesdayHours,
  Decimal wednesdayHours,
  Decimal thursdayHours,
  Decimal fridayHours,
  Decimal saturdayHours,
  Decimal sundayHours
){
  
  pse__Schedule__c s = newSchedule(false, startDate, endDate);
  
  s.pse__Monday_Hours__c    = mondayHours;
  s.pse__Tuesday_Hours__c   = tuesdayHours;
  s.pse__Wednesday_Hours__c = wednesdayHours;
  s.pse__Thursday_Hours__c  = thursdayHours;
  s.pse__Friday_Hours__c    = fridayHours;
  s.pse__Saturday_Hours__c  = saturdayHours;
  s.pse__Sunday_Hours__c    = sundayHours;
  
  if(isInsert){
    insert s;
  }
  return s;
}


// get the schedule by Id and return null if not found
public pse__Schedule__c getSchedule(Id scheduleId){
  List<pse__Schedule__c> lstSchedules = new List<pse__Schedule__c>([
    SELECT Id, 
           pse__Start_Date__c,
           pse__End_Date__c
      FROM pse__Schedule__c
     WHERE id = :scheduleId
  ]);
  
  if(lstSchedules.size() == 1){
    return lstSchedules[0];
  } else {
    return null;
  }
}


// --
// Schedule Exceptions
// --

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate
){
  
  // build a schedule 
  pse__Schedule_Exception__c s = new pse__Schedule_Exception__c(
    pse__Schedule__c = scheduleId,
    pse__Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Monday_Hours__c = 0, 
    pse__Tuesday_Hours__c = 0,
    pse__Wednesday_Hours__c = 0,
    pse__Thursday_Hours__c = 0,
    pse__Friday_Hours__c = 0,
    pse__Saturday_Hours__c = 0,
    pse__Sunday_Hours__c = 0
  );
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert,
  Id scheduleId
){
  
  // build a schedule 
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, Date.today(), Date.today());
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate,
  String schedulePattern
){
  
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, startDate, endDate);
  
  if(schedulePattern == null || 
     schedulePattern == '' || 
     schedulePattern == SCHEDULE_PATTERN_0 ){
    // do nothing - pattern of 0's
  } else if (schedulePattern == SCHEDULE_PATTERN_8x5){
    s.pse__Monday_Hours__c    = 8;
    s.pse__Tuesday_Hours__c   = 8;
    s.pse__Wednesday_Hours__c = 8;
    s.pse__Thursday_Hours__c  = 8;
    s.pse__Friday_Hours__c    = 8;
  } else if (schedulePattern == SCHEDULE_PATTERN_10x4){
    s.pse__Monday_Hours__c    = 10;
    s.pse__Tuesday_Hours__c   = 10;
    s.pse__Wednesday_Hours__c = 10;
    s.pse__Thursday_Hours__c  = 10;
    s.pse__Friday_Hours__c    = 0;
  } else if (schedulePattern == SCHEDULE_PATTERN_1){
    s.pse__Monday_Hours__c    = 1;
    s.pse__Tuesday_Hours__c   = 1;
    s.pse__Wednesday_Hours__c = 1;
    s.pse__Thursday_Hours__c  = 1;
    s.pse__Friday_Hours__c    = 1;
    s.pse__Saturday_Hours__c  = 1;
    s.pse__Sunday_Hours__c    = 1;
  }
  
  if(isInsert){
    insert s;
  }
  return s;
}

public pse__Schedule_Exception__c newScheduleException(
  Boolean isInsert, 
  Id scheduleId,
  Date startDate,
  Date endDate,
  Decimal mondayHours,
  Decimal tuesdayHours,
  Decimal wednesdayHours,
  Decimal thursdayHours,
  Decimal fridayHours,
  Decimal saturdayHours,
  Decimal sundayHours
){
  
  pse__Schedule_Exception__c s = newScheduleException(false, scheduleId, startDate, endDate);
  s.pse__Monday_Hours__c    = mondayHours;
  s.pse__Tuesday_Hours__c   = tuesdayHours;
  s.pse__Wednesday_Hours__c = wednesdayHours;
  s.pse__Thursday_Hours__c  = thursdayHours;
  s.pse__Friday_Hours__c    = fridayHours;
  s.pse__Saturday_Hours__c  = saturdayHours;
  s.pse__Sunday_Hours__c    = sundayHours;
  
  if(isInsert){
    insert s;
  }
  return s;
}


//----


public pse__Assignment__c newAssignment(
  Boolean isInsert, 
  Id projectId, 
  Id resourceId,
  Id scheduleId
){
  
  // create the Assignment using the normal user Resource
  pse__Assignment__c a = new pse__Assignment__c(
    Name                     = 'AssignmentName',
    pse__Project__c          = projectId,
    pse__Schedule__c         = scheduleId,
    pse__Bill_Rate__c        = RESOURCE_BILL_RATE_DEFAULT,
    pse__Is_Billable__c      = true,
    pse__Cost_Rate_Amount__c = RESOURCE_COST_RATE_DEFAULT,
    CurrencyIsoCode          = CURRENCY_DEFAULT,
    pse__Resource__c         = resourceId
  );
  if(isInsert){
    insert a;
  }
  return a;
}

// ============================================================================
// Timecards
// 
// Methods for retrieving and creating records of this type
// ============================================================================

public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate,
  Decimal sunHours,
  Decimal monHours,
  Decimal tueHours,
  Decimal wedHours,
  Decimal thrHours,
  Decimal friHours,
  Decimal satHours,
  String sunNotes,
  String monNotes,
  String tueNotes,
  String wedNotes,
  String thrNotes,
  String friNotes,
  String satNotes
  ){
  
  pse__Timecard_Header__c rec = new pse__Timecard_Header__c(
    pse__Resource__c = resourceId,
    pse__Project__c = projectId,
    pse__Assignment__c = assignmentId,
    pse__Milestone__c = milestoneId,
    pse__Start_Date__c = startDate,
    pse__End_Date__c = endDate,
    pse__Sunday_Hours__c = sunHours,
    pse__Monday_Hours__c = monHours,
    pse__Tuesday_Hours__c = tueHours,
    pse__Wednesday_Hours__c = wedHours,
    pse__Thursday_Hours__c = thrHours,
    pse__Friday_Hours__c = friHours,
    pse__Saturday_Hours__c = satHours,
    pse__Sunday_Notes__c = sunNotes,
    pse__Monday_Notes__c = monNotes,
    pse__Tuesday_Notes__c = tueNotes,
    pse__Wednesday_Notes__c = wedNotes,
    pse__Thursday_Notes__c = thrNotes,
    pse__Friday_Notes__c = friNotes,
    pse__Saturday_Notes__c = satNotes
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
  
}


public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate,
  Decimal sunHours,
  Decimal monHours,
  Decimal tueHours,
  Decimal wedHours,
  Decimal thrHours,
  Decimal friHours,
  Decimal satHours
){
  
  final String defaultNoteText = 'note';
  
  return newTimecardHeader(
    isInsert,
    resourceId,
    projectId,
    assignmentId,
    milestoneId,
    startDate,
    endDate,
    sunHours,
    monHours,
    tueHours,
    wedHours,
    thrHours,
    friHours,
    satHours,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText,
    defaultNoteText
  );
}


public pse__Timecard_Header__c newTimecardHeader(
  Boolean isInsert, 
  Id resourceId,
  Id projectId,
  Id assignmentId,
  Id milestoneId,
  Date startDate,
  Date endDate
){
  
  final Decimal defaultHours = 0.0;
  
  return newTimecardHeader(
    isInsert,
    resourceId,
    projectId,
    assignmentId,
    milestoneId,
    startDate,
    endDate,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours,
    defaultHours
  );
}

// ============================================================================
// Expense Reports 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Expense_Report__c newExpenseReport(
  Boolean isInsert,
  Id projectId,
  Id resourceId
){
  pse__Expense_Report__c rec = new pse__Expense_Report__c(
    pse__Project__c = projectId,
    pse__Resource__c = resourceId,
    pse__Status__c = EXPENSE_REPORT_STATUS_DRAFT,
    pse__Billable__c = true,
    CurrencyIsoCode = CURRENCY_DEFAULT
  );
  
  if(isInsert){
    insert rec;
  }
  return rec;
}


public pse__Expense__c newExpense(
  Boolean isInsert,
  Id expenseReportId
){
  
  return newExpense(
    isInsert,
    expenseReportId,
    NULL_ID,
    NULL_STRING,
    NULL_DECIMAL
  );
}


public pse__Expense__c newExpense(
  Boolean isInsert,
  Id expenseReportId,
  Id resourceId,
  String expenseType,
  Decimal expenseAmount
){
  
  List<pse__Expense__c> lstRecs = newExpenses(
    isInsert,
    expenseReportId,
    resourceId,
    expenseType,
    expenseAmount,
    1
  );
  return lstRecs[0];
}


public List<pse__Expense__c> newExpenses(
  Boolean isInsert,
  Id expenseReportId,
  Id resourceId,
  String expenseType,
  Decimal expenseAmount,
  Integer recCount
){
  
  if(recCount == null || recCount < 1){
    recCount = 1;
  }
  
  if(expenseType == null || expenseType == ''){
    expenseType = EXPENSE_EXPENSE_TYPE_DEFAULT;
  }
  
  if(expenseAmount == null){
    expenseAmount = EXPENSE_AMOUNT_DEFAULT;
  }
  
  List<pse__Expense__c> lstRecs = new List<pse__Expense__c>();
  for(Integer i = 0 ; i < recCount ; i++){
    pse__Expense__c rec = new pse__Expense__c(
      pse__Expense_Report__c = expenseReportId,
      pse__Resource__c = resourceId,
      //pse__Project__c = projectId,
      pse__Expense_Date__c = Date.today().addDays(i+2),
      pse__type__c = expenseType,
      pse__Description__c = EXPENSE_REPORT_DESC_DRAFT,
      //pse__Status__c = EXPENSE_REPORT_STATUS_DRAFT,
      pse__Billable__c = true,
      pse__Amount__c =  expenseAmount
    );
    lstRecs.add(rec);
  }
  
  if(isInsert){
    insert lstRecs;
  }
  return lstRecs;
}

// ============================================================================
// Rate Cards
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Rate_Card__c  newRateCard(
  Boolean isInsert,
  Id regionId
){
  pse__Rate_Card__c rec = new pse__Rate_Card__c(
    pse__Role__c = CONSULTANT_ROLENAME_DEFAULT, 
    pse__Region__c = regionId, 
    pse__Account__c = null,
    pse__Cascading_Role__c = true, 
    pse__Suggested_Bill_Rate__c = 160,
    pse__Average_Cost_Rate__c = 100
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}


public  pse__Rate_Card__c newRateCard(
  Boolean isInsert,
  Id regionId,  // A value for either regionId OR accountId should be passed in
  Id accountId, // NOT BOTH
  String roleName, 
  Boolean cascadingRole, 
  Decimal billRate, 
  Decimal costRate 
){
  pse__Rate_Card__c rec = new pse__Rate_Card__c(
    pse__Region__c = regionId, 
    pse__Account__c = accountId,
    pse__Role__c = roleName, 
    pse__Cascading_Role__c = cascadingRole, 
    pse__Suggested_Bill_Rate__c = billRate,
    pse__Average_Cost_Rate__c = costRate
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}


// ============================================================================
// Billing Events 
// 
// Methods for retrieving and creating records of this type
// ============================================================================
public pse__Billing_Event__c  newBillingEvent(
  Boolean isInsert,
  ID projectID
){
  pse__Billing_Event__c rec = new pse__Billing_Event__c(
    pse__Project__c = projectID
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}


public  pse__Billing_Event_Item__c newBillingEventItem(
  Boolean isInsert,
  Id billingEvtID,
  String objectID,
  String category,
  ID projectID
){
  pse__Billing_Event_Item__c rec = new pse__Billing_Event_Item__c(
    pse__Billing_Event__c = billingEvtID,
    pse__Object_Id__c =  objectID,
    pse__Category__c = category,
    pse__Project__c = projectID
  );
  if(isInsert){
    insert rec;
  }
  return rec;
}

// *************************************************************************************************
// PSA UTILITY METHODS
// *************************************************************************************************


} // end of class