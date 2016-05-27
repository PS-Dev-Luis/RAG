/**
*	DimensionCreationHandler
*	=========================
*	Handler class for the following actions: insert Project.
*	Generates a Dimesions for the inserted Projects, the new Dims are used by 
*	the WIP report to gather associated transaction data.
*
*	Luis Valenzuela 11/04/2013
* 
*/
public with sharing class DimensionCreationHandler 
{
	public static void handleProjectInsert( map <id, pse__Proj__c> projects )
	{
		map <id, pse__Proj__c> projectCodes = new map <id, pse__Proj__c> ( [Select id, Project_Code__c from pse__Proj__c where id in : projects.keyset()] );
		list <c2g__codaDimension3__c> newDims = new list <c2g__codaDimension3__c>();
		for( pse__Proj__c proj : Projects.values() )
		{
			newDims.add(new c2g__codaDimension3__c(  name = projectCodes.get(proj.id).Project_Code__c,  
													 c2g__ReportingCode__c = projectCodes.get(proj.id).Project_Code__c,  
													 project__c = proj.id,
													 CurrencyIsoCode = proj.CurrencyIsoCode ));
		}
		
		try 
		{ 
			insert newDims; 
		}
        catch(DMLException e) 
        { 
        	// Fail gracefully and don't stop insert of Project.
        	Log.warn('Failed to create new Dimensions after Project insert: \n' + e.getMessage());
        }
	}	
 

	public static void createEmployeeDims( map<String, Contact> employeeCodes )
	{
		list<c2g__codaDimension4__c> newDims = new list<c2g__codaDimension4__c>();
		for( String code : employeeCodes.keySet() )
		{
			newDims.add(new c2g__codaDimension4__c(  name = code,  
													 c2g__ReportingCode__c = code,  
													 employee__c = employeeCodes.get(code).id,
													 CurrencyIsoCode = employeeCodes.get(code).CurrencyIsoCode ));
		}
		try 
		{ 
			upsert newDims; 
		}
        catch(DMLException e) 
        {  
        	// Fail gracefully and don't stop insert of Project.
        	throw new AppException('Failed to create new Dimensions after Contact insert: \n' + e.getMessage());
        }
	}	
}