public with sharing class SObjectHelper 
{

	public static sObject enrichSObject(sObject theObject, String[] requiredFields)
	{
		return theObject;
	}
	
	public static map<id,sObject> enrichSObject(list<sObject> theObjects, String[] requiredFields)
	{
		return new map<id, sObject>(theObjects);		
	}

	public static map<id,sObject> enrichSObject(map<id,sObject> theObjects, String requiredFields)
	{
		if( theObjects.isEmpty() ) return null;
		
		set<id> ids = theObjects.keyset();
		String queryString = 'SELECT id, ' + requiredFields +
							' FROM ' + theObjects.values()[0].getsObjectType() +
							' WHERE id in :ids';
		map<id, sObject> refreshedFields = new Map<id,sObject> ( Database.query( queryString) );
		String[] fieldNames = requiredFields.split(',',-1);
		for(id currentId : ids )
		{
			for(String field : fieldNames)
			{
				theObjects.get(currentId).put( field.trim() , refreshedFields.get(currentId).get( field.trim() ) );
			}
		}
		return theObjects;
	}
	

}