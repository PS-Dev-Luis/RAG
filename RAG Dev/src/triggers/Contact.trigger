trigger Contact on Contact (before insert, before update, after insert, after update ) 
{
	// Create Employee code for Contacts with record type of Employee
	public static map<String, Contact> employeeCodes = new map<String, Contact>();
	static boolean hasRan = false;
	
	
	if( trigger.isBefore && hasRan == false )
	{
		id EmplRecTypId = [Select Id From RecordType where DeveloperName = 'Employee' and SobjectType = 'Contact'][0].id;
		integer maxEmployeeNo;
		List<aggregateResult> results = [select max(c.employeeNumber__c) maxNo from contact c where employeeNumber__c != null ];
		maxEmployeeNo = results[0].get('maxNo') != null ? integer.valueof( results[0].get('maxNo') ) : 0;
	
		for( Contact con : trigger.new )
		{
			if( con.RecordTypeId == EmplRecTypId && (con.employeeCode__c == null || con.employeeCode__c == '') )
			{
				maxEmployeeNo++;
				String employeeCode = ( con.firstName != null ? con.firstName.left(1).toUpperCase() : '' ) 
										+  ( con.lastName != null ? con.lastName.left(3).toUpperCase() : '' )
											+  String.valueOf(maxEmployeeNo).leftpad(4, '0') ;
				con.employeeCode__c = employeeCode;
				con.employeeNumber__c = maxEmployeeNo;
				employeeCodes.put(con.employeeCode__c, con );
			}
		}
	}

	if( trigger.isAfter && hasRan == false )
	{
		if( !ConfigSettings.isGenerateContactDimension_Disabled() )
		{
			for( Contact employee : trigger.new )
			{
				if( employee.employeeCode__c != null 
					&& 
					( trigger.oldMap == null 
						|| trigger.oldMap.get(employee.id) == null 
							|| trigger.oldMap.get(employee.id).employeeCode__c != employee.employeeCode__c ) ) 
				{
					employeeCodes.put( employee.employeeCode__c, employee );
				}				
			}		
			DimensionCreationHandler.createEmployeeDims( employeeCodes );	 		
		}	
		hasRan = true;
	}
}