public with sharing class ProjectCodeHandler 
{
	public static map<String,String> regionCodeMap;
	public static map<String,String> practiceCodeMap;
	
	/**
	 *		Get Project Codes
	 *		-----------------
	 *		Build project code maps from custom settings.
	 **/
	public static void getProjectCodes()
	{
		if( regionCodeMap == null || practiceCodeMap == null )
		{
			regionCodeMap = new map<String,String>();
			practiceCodeMap = new map<String,String>();
			
			for( ProjectCodeMappings__c pcm : [Select type__c, FullName__c, code__c from ProjectCodeMappings__c] )
			{
				if( pcm.type__c == 'Both' )
				{
					regionCodeMap.put( pcm.FullName__c, pcm.code__c );
					practiceCodeMap.put( pcm.FullName__c, pcm.code__c );
				} 
				else if( pcm.type__c == 'Region' )
				{
					regionCodeMap.put( pcm.FullName__c, pcm.code__c );
				} 
				else if ( pcm.type__c == 'Practice' )
				{
					practiceCodeMap.put( pcm.FullName__c, pcm.code__c );
				}
				
			}
		}
	}

	/**
	 *		Create Codes
	 *		-----------
	 *		Create Project codes in the form of <Account Code><Year YY><Auto Number XXXXXX><Region Code><Practice Code>
	 **/
	public static void createCodes( map <id, pse__Proj__c> projs)
	{
		getProjectCodes();
		set<id> projIds = projs.keySet();
		String dbQuery = 'Select id,									'+
						 '		 pse__Account__r.Client_Code__c,		'+
						 '		 pse__Region__r.Name, 					'+
						 '		 is_internal_project__c,				'+
						 '		 Project_Code__c,						'+
						 '		 pse__Project_ID__c,					'+
						 '		 pse__Practice__r.Name					'+
						 '	From pse__Proj__c							'+		
						 '			   where id in :projIds				';
						 
		map <id, pse__Proj__c> dbProjs = new map <id, pse__Proj__c> ( (list<pse__Proj__c>) Database.query(dbQuery) );
		
		for(pse__Proj__c proj : dbProjs.values() )
		{
			if(proj.is_internal_project__c)
			{
				// Do not create proj code for internal projects
				continue;
			}
			
			String projId = String.valueOf(proj.pse__Project_ID__c); 
			String regCode = regionCodeMap.get( proj.pse__Region__r != null ? proj.pse__Region__r.name : '' ); 			
			String pracCode = practiceCodeMap.get( proj.pse__Practice__r.name );

			// Add Account code
			Account projAcc =  proj.pse__Account__r;
			proj.Project_Code__c = ((projAcc != null && projAcc.get('Client_Code__c') != null ) ? (string) projAcc.get('Client_Code__c') : '' )
										// Add Year
										+ String.valueOf( System.now().year() ).right(2)
											// Add Auto Number - ProjId = PR - {xxxxxx}
											+ projId.removeStart( 'PR-')	
												// Add Region code - Region should not be Blank due to validation on Project trigger
												+ ( regCode != null ? regCode : '' )
													// Add Practice code - Practice should not be blank due to validation on Project trigger
													+ ( pracCode != null ? pracCode : '' );
		}
		
		list<pse__Proj__c> updateProj  = dbProjs.values();
		Database.SaveResult[] lsr = Database.update( updateProj, false);
		for ( integer i = 0; i < ( lsr.size() - 1) ; i++ )
		{
    		if(!lsr[i].isSuccess()) 
    		{
    			log.debug(lsr);
				projs.get( updateProj[i].Id ).addError('Could not create Project code : ' +  lsr[i].getErrors() );    			
    		}
		}
	}
}