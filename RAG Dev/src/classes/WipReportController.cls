/**
*   WipReportController
*   =====================
*   Controller class to  control WIP reports from Projects.  Used by
*   WipReport VF page.  
*
*   Luis Valenzuela 25/03/2013
*
*/
public with sharing class WipReportController 
{
    public WipReport__c wipReport {get; private set;}
    public WipReportGenerator generator;
    public GlSettings glSet{get; private set;} 
    public ApexPages.StandardController controller;
    
    public static final String WIP_DATE_REPORT_NAME = 'WipTransactions'; 
    public static final String WIP_PERIOD_REPORT_NAME = 'WipTransactionsByPeriod'; 
        
    // Constructors
    public WipReportController() 
    {
        this.wipReport = new wipReport__c();
        this.generator = new WipReportGenerator ();
    }
    
    public WipReportController(ApexPages.StandardController ctrl) 
    {
        this.controller = ctrl;
        glSet = new GlSettings();
        this.wipReport = (WipReport__c) controller.getRecord();
        this.generator = new WipReportGenerator();
        // Page Warnings
        if ( this.wipReport.status__c == refData.WIP_STATUS_PEND ) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                'Generation of WIP report in process, please refresh the page and try again later. ' ) );
        }
    }   
    
    // Generate Report Action
    public Pagereference generateWipReport()
    {
        wipReport.status__c = refData.WIP_STATUS_PEND;
        wipReport.name = 'WIP Report - Pending ' + date.today().format();
        insert wipReport;
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                'WIP report scheduled for generation for project: ' + this.wipReport.project__c +
                    ' for period up to date: ' + wipReport.snapshotdate__c));
        
        generator.generateWipReport( 	new pse__proj__c( id = this.wipReport.project__c), 
	                    				this.wipReport.snapShotDate__c,  
	                    				this.wipReport,
										ApexPages.currentPage().getParameters().get('selectorType') );
										
        PageReference wipListPage = new ApexPages.StandardController(wipReport).view();
        wipListPage.setRedirect(true);
        return wipListPage;
    }
    
    
    // Variable for holding WIP transaction reporting URL, report has to be set up with name == WIP_REPORT_NAME
    public String wipReportURL 
    {
        get
        {
        	String reportName = this.wipReport.filterType__c == RefData.WIP_REPORT_FILTER_TYPE_PERIOD ?
        						 WIP_PERIOD_REPORT_NAME : WIP_DATE_REPORT_NAME; 
            if( wipReportURL == null )
            {
                List<Report> wipReportList = [ select Id from Report where DeveloperName = :reportName ];
                if( wipReportList.size() == 0 )
                {
                    throw new AppException( 'Cannot render View. Report for name ['+ reportName +'] not found.' );
                }
                else if( wipReportList.size() > 1 )
                {
                    throw new AppException( 'Cannot render View. More than 1 Report for name ['+ reportName +'] found.' );
                }
                else
                {
                    wipReportURL = '/' + wipReportList[0].Id;
                }
            }
            return wipReportURL;
        }
        private set { wipReportURL = value; }
    }
    
    
    // Variable for holding WIP Project Dimension
    public String wipReportDimId 
    {
        get
        {
            if( wipReportDimId == null )
            {
                List<c2g__codaDimension3__c> projDims = [ select Id from c2g__codaDimension3__c where Project__c = :this.wipReport.project__c ];
                if( projDims.size() == 0 )
                {
                	wipReport.addError('Wip report cannot be generated as Dimension 3 for project does not exist.');
                    throw new AppException( 'Cannot find Dimension 3 for project ['+ this.wipReport.project__c +'].' );
                }
                else if( projDims.size() > 1 )
                {
                	wipReport.addError('Wip report cannot be generated as more than 1 Dimension 3 for project exists.');
                    throw new AppException( 'More than 1 Dimension 3 found for project ['+ this.wipReport.project__c +'] found.' );
                }
                else
                {
                    wipReportDimId = projDims[0].Id;
                }
            }
            return wipReportDimId;
        }
        private set { wipReportDimId = value; }
    }
    
    // Variable for holding WIP date in MM/DD/YYYY format encoded for passing to Report via URL
    public String wipReportSnapshotDate 
    {
        get
        {
            if( wipReportSnapshotDate == null )
            {
                if( this.wipReport.snapShotDate__c == null ) return '';
                wipReportSnapshotDate = ''+ this.wipReport.snapShotDate__c.month() + '/' +
                                            this.wipReport.snapShotDate__c.day() + '/' + 
                                            this.wipReport.snapShotDate__c.year() ;
            }
            return wipReportSnapshotDate;
        }
        private set { wipReportSnapshotDate = value; }
    }
    
    
    // Variable for holding list of all Gl ids
    public String wipReportGlList
    {
        get
        {        	
            if( wipReportGlList == null )
            {
                for(String glRepCode : GlSettings.rptToGlMap.keyset() )
                {
    				if( glRepCode == GlSettings.authExpRepCode || glRepCode == GlSettings.actualExpRepCode )
    				{
						// The wildcarded lists have already been substringed to 15 chars
	                	wipReportGlList = ( wipReportGlList == null ? 
	                		GlSettings.rptToGlMap.get(glRepCode) : wipReportGlList + ',' +  GlSettings.rptToGlMap.get(glRepCode) );          
    				}
    				else
    				{
	                	// List of all the GL ids
	                	wipReportGlList = ( wipReportGlList == null ? 
	                		GlSettings.rptToGlMap.get(glRepCode).left(15) : wipReportGlList + ',' +  GlSettings.rptToGlMap.get(glRepCode).left(15) );                	
    				}
                }   
            }
            return wipReportGlList;
        }
        private set { wipReportGlList = value; }
    }
        
    
    /**********************
     * Standard Actions   *
     **********************/
    public PageReference cancel()
    {
        return controller.cancel();
    }
    
    public class AppException extends Exception{}
    
}