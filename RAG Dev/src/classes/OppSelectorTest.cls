@istest
public with sharing class OppSelectorTest {
    @istest
    static void testGetOpps()
    {
        List<Opportunity> ol = new OpportunitySelector().getOpps(new List<Id>());
        system.assertEquals(0, ol.size());
    }
}