/**
 * Generic Class to Hold processing results and report errors.
 **/ 
public with sharing class Result 
{

	public set<Id> resultIds { get; set; }
	public list<sObject> resultSObjects { get; set; } 
	public String errorMsg { get; set; }
	public ErrorType errorStatus { get; set; }
	
	public Result()
	{
		resultIds = new set<Id>();
		errorStatus = ErrorType.OK;
	}
	
    public enum ErrorType
    {
    	OK,
        INFO,
        WARN,
        ERROR
    }
}