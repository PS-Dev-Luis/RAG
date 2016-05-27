@isTest (seeAllData = true)
public with sharing class TriggerHandlerTests {

    @istest static void testProjectTriggerHandler()
    {
        pse__Proj__c p = testHelper.setupProject( 'Test 1 Proj' );
        insert p;
        update p;
    }

    @isTest static void testOpportunityTriggerHandler()
    {
        Opportunity o = testHelper.setupOpportunity('Test 1 Opp');
        o.stagename = 'Closed Won';
        o.closedate = date.today();
        insert o;
        update o;
    }
}