@isTest (seeAllData = true)
public with sharing class TestMiscAdjustController 
{

    @isTest (seeAllData = true)
    public static void testMiscAdjController()
    {

        /* Setup */
        // Create a Project for approval.
        opportunity opp = TestHelper.setupOpportunity('Test Opp 5');
        insert opp;
        // Create a Project for approval.
        pse__Proj__c project = TestHelper.setupProject( 'Test Project 5' );
        project.pse__Opportunity__c = opp.id;
        insert project;

        test.startTest();

        /* Test Controller */
        PageReference pageRef = Page.MiscAdjustmentNew;
        Test.setCurrentPage(pageRef);
  		ApexPages.currentPage().getParameters().put('id', project.Id);
  
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController( new list<pse__Miscellaneous_Adjustment__c>() );
        MiscAdjustmentController miscAdjCtrl = new MiscAdjustmentController(ssc);
         
        /* Test the autocomplete functionality */
        List<MiscAdjustmentController.SearchResult> results = MiscAdjustmentController.autocompleteProduct('Gen', project.currencyIsoCode, false, '01/01/2015' );
        system.assert(results.size() > 0 , 'No Products were found with autocomplete.' );

        /* Test the insert functionality */ 
        list<MiscAdjustmentController.newMiscAdj> newMiscAdjs = new list<MiscAdjustmentController.newMiscAdj>();
        
        MiscAdjustmentController.newMiscAdj miscAdj = new MiscAdjustmentController.newMiscAdj();
        miscAdj.prodId = results[0].RecordId;
        miscAdj.miscDate =  '01/01/2015';
        miscAdj.Name = 'Test Name';
        miscAdj.amount = '500';
        miscAdj.cat = 'cat';
        miscAdj.isCaseMiscAdj = false;
        
        newMiscAdjs.add(miscAdj);
        
        MiscAdjustmentController.saveMiscAdjs( newMiscAdjs, project.id, new list<id>() );
            
        test.stopTest();
    }

}