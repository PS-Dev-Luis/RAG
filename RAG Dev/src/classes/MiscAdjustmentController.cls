public with sharing class MiscAdjustmentController 
{
    public ApexPages.StandardController controller;
    public ApexPages.StandardSetController setController;
    public pse__Proj__c project {get;set;}
    public static pse__Proj__c statProject {get;set;}
    public id projid {get;set;}
    public static String projCode {get;set;}
    public String accId {get;set;}
    public id priceBookId;
    
    public string DateFormat { get; set; }
    public String todayString { get {return Datetime.now().format('dd/MM/YYY');} set;}    
    public String todayStringYYYYMMDD { get {return Datetime.now().format('YYYYMMdd');} set;}    
    public string locale { get; set; }

	// Custom permission Edit_Misc_Adj_Price needed to edit case adjustments     
    public integer allocatedCasesNo { get; set; }
    public integer unAllocatedCasesNo { get; set; }
    public list<id> unallocatedCasesId_lst { get; set; }
    public String unallocatedCasesId_seialLst { get{ return JSON.serialize(unallocatedCasesId_lst); } set; }

    public SearchResult caseProduct { get; set; }   
    public Date fDate { get; set; }
 
    public MiscAdjustmentController( ApexPages.StandardSetController ssCtrl ) 
    {    	
        allocatedCasesNo = 0;
    	unAllocatedCasesNo = 0;
    	unallocatedCasesId_lst = new list<id>();
    	
        projId =  System.currentPagereference().getParameters().get('id');
        String query =	' select id,														'+
						'		name, 														'+
						'		pse__Account__c,											'+
						'		ffps_0387__Project_Code__c,									'+
						'		pse__Account__r.Name,										'+
						'		pse__Account__r.Hierarchy_Group_ID__c,						'+
						'		pse__Account__r.CurrencyIsoCode,							'+
						'		pse__Region__r.ffpsai__OwnerCompany__r.id,					'+
						'		CurrencyIsoCode,  											'+	
						'		pse__Opportunity__r.Pricebook2Id 							'+
						'	from 															'+
						'		pse__Proj__c where Id = :projId								';
        
        list<pse__Proj__c> projects = Database.query(query); 	
        
        if( projects.size() > 0 )
        {
			project = projects[0];
			projCode = project.ffps_0387__Project_Code__c;
			statProject = project;

			// Check Company
			c2g__codaCompany__c currComp = FFUtil.getCurrentCompany();
			c2g__codaCompany__c projComp = project.pse__Region__r.ffpsai__OwnerCompany__r; 
			if( projComp == null || projComp.Id != currComp.Id )
			{
				String errorMsg = (projComp == null ? 'Entity(Region) must have a valid Owner Company.'
														: 'You cannot insert/update this project unless your current Company is set as \"' + projComp.Name + '\".'  ) ;
				throw new AppException( errorMsg );
			}
						
			// Find unallocated cases
			accId = project.pse__Account__r != null 
						? String.valueOf( project.pse__Account__r.get('Hierarchy_Group_ID__c') ).left(15) 
						: null;
			
			if(accId != null)
			{
				log.debug( 'Acc Id' );
				log.debug( accId );

				for( case cas : Database.query( ' Select id, 					 					'+
												'		billing_status__c, 							'+
												'		account.Hierarchy_Group_ID__c 				'+
												'	from case 										'+
												'	where account.Hierarchy_Group_ID__c = :accId ') )
				{
					log.debug( 'Case' );
					log.debug( cas );
					if( cas.billing_status__c == 'Unallocated' )
					{
						unAllocatedCasesNo++;
						unallocatedCasesId_lst.add( cas.id );
					}
					else
					{
						allocatedCasesNo++;
					}
				}
			}
			
			// Find case product
	        priceBookId = ( project.pse__Opportunity__r != null ? project.pse__Opportunity__r.Pricebook2Id : null);
	        id caseProductId = CustomSettings__c.getInstance().Case_Product_Id__c;
	        list<Product2> prods = [ Select	id, 
			        						name, 
			        						ProductCode, 
											(Select Pricebook2Id,
													UnitPrice,
													CurrencyIsoCode
												From 
													PricebookEntries)
		        						from Product2 where id = :caseProductId ];
			
			if( prods.size() != 1)
			{
				throw new AppException('Case Product not found, please specify correct id in custom settings.');
			}
			else
			{
				Product2 sfCaseProd  = prods[0];
				caseProduct = new SearchResult();
				caseProduct.recordId = sfCaseProd.id; 
				caseProduct.Name = sfCaseProd.Name;
				
				list<sObject> accSobjs = Database.query( 'select id, caseProductPrice__c from Account where id = :accId' );
				// If price set on Account then use that otherwise use product
				if( accSobjs != null && accSobjs.size() > 0 && accSobjs[0].get('caseProductPrice__c') != null)
				{ 
					Account acc = (Account)accSobjs[0];
					decimal accAmount = (decimal)(acc.get('caseProductPrice__c'));
					caseProduct.Info = String.valueOf( CurrencyHelper.convertFromTo(accAmount, acc.CurrencyIsoCode, project.CurrencyIsoCode, system.today()) );
				}
				else
				{
					caseProduct.Info = getProjectCurrencyPrice( project.CurrencyIsoCode, sfCaseProd, system.today() );
				}
				caseProduct.Code = sfCaseProd.productCode;
			}
        }						
        else
        {
        	String errMsg = 'Unexpected error: a Project must be selected.'; 
        	throw new AppException( errMsg );
        }

        this.setController = ssCtrl;
        DateFormat = LocaleHelper.getDateFormat(); 
        locale = UserInfo.getLocale().subString( 0, 2 );
        
        Log.sendDebugEmail();
    }   
    

    
    	
	public list<SelectOption> getAccCurrencies() 
	{
        list<SelectOption> accCurrencies = new list<SelectOption>();
        for( String curr  : CurrencyHelper.getAllAccCurrencies().keyset() )
        {	
        	accCurrencies.add( new SelectOption(curr,curr) );  
        }
        return accCurrencies;
	}
  
  
  
    @RemoteAction
    public static List<SearchResult> autocompleteProduct( string terms, string projCurrencyCode, boolean variablePrice, string dateString )
    {
    	
    	date effectivedate = Date.parse(dateString);
        List<SearchResult> results = new List<SearchResult>();
        string queryTerms = '%' + terms + '%';

		string query = 	'Select	Id, 										'+
						'		Name,										'+
						'		ProductCode,								'+
						'		(Select Pricebook2Id, 						'+
						'				UnitPrice, 							'+
						'				CurrencyIsoCode 					'+
						'			From PricebookEntries) 					'+
						'	 From											'+ 
						'		Product2									'+
						'	where 											'+
						'		Name like :queryTerms						'+
						'		and BalancingGLACode__c != \'\' 			'+
						'		and MiscAdjGLACode__c != \'\'				'+
						( variablePrice ? ' and variablePriceMiscAdj__c = true ' 
										: ' and variablePriceMiscAdj__c = false ' )+
						'		limit 20									';
						      
        for( Product2 prod : Database.query(query) )
        {
            SearchResult res = new SearchResult();
            res.RecordId = prod.Id;
            res.Name = prod.Name;
            res.Code = prod.ProductCode;
            res.info = getProjectCurrencyPrice( projCurrencyCode, prod, effectivedate);
            results.add( res );
    	}

        return results;
    }
    
        
    @RemoteAction
    public static void saveMiscAdjs( newMiscAdj[] newMiscAdjs, String projId, list<id> unallocatedCasesId_lst ) 
    {   
    	Log.debug( newMiscAdjs );      
    	Log.debug( 'MISC ADJ' );    
    	  
        if(newMiscAdjs == null || newMiscAdjs.size() == 0)
        {
	    	Log.debug( 'EXCEPTION' );      
        	throw new appException('No adjustments created.');
        }

		// Get Products        
        list<id> prodIds = new list<id>(); 
        for( newMiscAdj miscAdj : newMiscAdjs )
        {
            prodIds.add( miscAdj.prodId );
        }
        prodIds.add(CustomSettings__c.getInstance().Case_Product_Id__c);

        map<id,product2> products = new map<id,product2>();
        for( Product2 prod : [Select Id,  
                                     ffps_0387__BalancingGLACode__c,
                                     ffps_0387__MiscAdjGLACode__c
                                 From Product2 
                                where id in :prodIds ])
        {
            products.put( prod.id, prod );
        }
      
		boolean setCaseMiscAdj = false;
		integer caseMiscAdjNo;

		// Get Proj Currency
		pse__proj__c proj = [select id, currencyIsoCode from pse__proj__c where id = : projId ];				
		c2g__codaAccountingCurrency__c projCurr =  CurrencyHelper.getAllAccCurrencies().get( proj.currencyIsoCode );
		if( projCurr == null )
		{
			String errMsg = 'Unable to find accounting currency '+ proj.currencyIsoCode + ' for current company.';
			throw new AppException(errMsg);
		}

        list<pse__Miscellaneous_Adjustment__c> miscSojbs = new list< pse__Miscellaneous_Adjustment__c>();
        for( newMiscAdj miscAdj : newMiscAdjs )
        {
            Product2 prod = products.get(miscAdj.prodId);
            
            // convert date dd/mm/yyyy
            Integer years = Integer.valueof( miscAdj.miscDate.substring(6,10));
            Integer months = Integer.valueof( miscAdj.miscDate.substring(3, 5));
			Integer days = Integer.valueof( miscAdj.miscDate.substring(0, 2));
            
			Date miscAdjDate = Date.newInstance(years, months, days);
			            
            miscSojbs.add( new pse__Miscellaneous_Adjustment__c ( name = miscAdj.name,
                                                                  pse__Effective_Date__c = miscAdjDate,
                                                                  pse__project__c = projId,
                                                                  ffpsai__ServicesProduct__c = prod.Id,
                                                                  ffpsai__MiscellaneousAdjustmentCurrency__c = projCurr.id ,
                                                                  ffpsai__MiscAdjGLACode__c = prod != null ? prod.ffps_0387__MiscAdjGLACode__c : null,
                                                                  ffpsai__BalancingGLACode__c = prod != null ? prod.ffps_0387__BalancingGLACode__c : null,
                                                                  pse__Amount__c =  decimal.valueOf( miscAdj.amount) ,
                                                                  pse__Transaction_Category__c = miscAdj.cat) );
                                                                  
			if( miscAdj.isCaseMiscAdj )
			{
				setCaseMiscAdj = true;
				caseMiscAdjNo = miscSojbs.size() - 1;
			}
        }
        
        // Update the cases to show they have been allocated
        insert miscSojbs;
        list<case> case_lst = new list<case>();
        if(setCaseMiscAdj)
        {
        	for(id caseId : unallocatedCasesId_lst)
        	{
        		case updateCase = new case( id = (id)caseId, Miscellaneous_Adjustment__c = miscSojbs[caseMiscAdjNo].id);
        		case_lst.add(updateCase);
        	}	
        }
        upsert case_lst;
    }   
    
    
    @RemoteAction
    public static decimal convertAmount( String amount, string chosenCurrency, string projCurrencyCode, String effectiveDate )
    {
    	if(amount == '' || amount == null)
    	{
    		return 0;
    	}
    	return CurrencyHelper.convertFromTo( decimal.valueOf( amount.trim() ),  chosenCurrency, projCurrencyCode,  Date.parse(effectiveDate) );
    }
    
    
    /**
     * 	Get Project Currency Price
     *	--------------------------
     *	Convenience method to return Product price in Project currency even if no pricebook entry in that currency.
     **/
    private static String getProjectCurrencyPrice( String projCurrencyCode, Product2 prod, date effectiveDate)
    {
        decimal realPrice;
        decimal exchangePrice = 0;  				// Default in case no price set
        String exchangeCurrency;
        String returnPriceString;
        
        for( PricebookEntry pbe : prod.PricebookEntries )
        {
        	if( pbe.CurrencyIsoCode == projCurrencyCode )
        	{
        		realPrice = pbe.UnitPrice;
        	}
        	else
        	{
        		exchangeCurrency = pbe.CurrencyIsoCode;
        		exchangePrice = pbe.UnitPrice;
        	}
        }
        
        if( realPrice != null )
        {
            returnPriceString =  String.valueOf( realPrice );
        }
        else
        {
        	decimal convertedPrice;
    		convertedPrice = exchangePrice == 0 ? 0 : CurrencyHelper.convertFromTo( exchangePrice, exchangeCurrency, projCurrencyCode, effectiveDate );
            returnPriceString =  String.valueOf( convertedPrice );
        }	
        
        return returnPriceString;
    } 
    
    /*******************/
    /* Utility Classes */
    public class SearchResult
    {
        public string RecordId { get; set; }
        public string Name { get; set; }
        public string Info { get; set; }
        public string Code { get; set; }
    }

    public class newMiscAdj
    {
        public string prodId { get; set; }
        public string miscDate { get; set; }
        public string Name { get; set; }
        public string amount { get; set; }
        public string cat { get; set; }
        public boolean isCaseMiscAdj { get; set; }
    }
}