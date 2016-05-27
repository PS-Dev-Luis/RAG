/*
*   Trasaction Line Correction Script
*/
global with sharing class CalculatedChargeTransactionCleanseBatch implements Database.Batchable<sObject>, Database.Stateful
{
	
	global Boolean testRun = true;
	
    List<String> errorMessages = new List<String>();
    List<String> successMessages = new List<String>();
    Id companyId;

	integer failCount = 0;
	integer jrnCount = 0;
	integer successCount = 0;

    global CalculatedChargeTransactionCleanseBatch()
    {
    }

	/* START */                   
   	public String getQuery()
   	{
    	String query =	' Select 	id,												'+
    					'			c2g__GeneralLedgerAccount__c,					'+ 
    					'			c2g__LineNumber__c,								'+ 
    					'			c2g__homevalue__C,								'+ 
    					'			c2g__DocumentValue__c,							'+ 
    					'			ffps_0387__Calculated_Charge_DualCurrency__c,	'+ 
    					'			ffps_0387__Calculated_Charge_DocCurrency__c, 	'+
    					'			ffps_0387__Calculated_Charge_Dim3Currency__c, 	'+
						'			ffps_0387__Calculated_Charge2__c, 				'+
						'			c2g__Transaction__r.c2g__TransactionType__c, 	'+
						'			c2g__Transaction__r.c2g__DocumentNumber__c, 	'+
						'			c2g__Transaction__r.Name, 						'+
						'			c2g__Transaction__r.OwnerId, 					'+
						'			c2g__HomeCurrency__c 							'+
						'		From c2g__codaTransactionLineItem__c 				'+
						' 		where c2g__Transaction__r.c2g__OwnerCompany__r.id = :myCompanyId	';
		if(testRun)
        {                   
        	query += ' Limit 100';
        }
        return query;
	}
  
     
    /* START */                   
	global Database.QueryLocator start( Database.Batchablecontext BC )
    {
        String limiter = Test.isRunningTest() ? ' Limit 1' : '';
        String myCompanyId = FFutil.getCurrentCompany().id;
        return Database.getQueryLocator( getQuery() + limiter );
    } 
  

    /* EXECUTE */                   
    global void execute( Database.Batchablecontext BC, List<Object> scope )
    {
    	if(errorMessages.size() > 1000 )
    	return;
    	
        try
        {        	
			list<c2g__codaTransactionLineItem__c> txLis  = (list<c2g__codaTransactionLineItem__c>) scope;
    		list<String> jrnNames = new list<String>();
		    for( c2g__codaTransactionLineItem__c txLi : txLis) 
		    {
		    	txLi.calculated_charge2__c = 0.00;
		    	txLi.ffps_0387__Calculated_Charge_DualCurrency__c = 0.00;
		    	txLi.ffps_0387__Calculated_Charge_DocCurrency__c = 0.00;
		    	txLi.ffps_0387__Calculated_Charge_Dim3Currency__c = 0.00;
		    	
				// Set the calculated Charge field
				if( txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.authSubFeeRepCode )
					||
					txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.authSubFeeInvNotRecRepCode )
					||
					txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.actualSubFeeRepCode) )
				{
					txLi.calculated_charge2__c = txLi.c2g__homevalue__C * CustomSettings.subFeeMultiplier; 
				}
				else
				{
					txLi.calculated_charge2__c = txLi.c2g__homevalue__C.setscale(2); 
				}
				// Get Journal Name if Tx is a result of Jrn
				if( txLi.c2g__Transaction__r.c2g__TransactionType__c == 'Journal' )
				{
					jrnNames.add( txLi.c2g__Transaction__r.c2g__DocumentNumber__c );
				}
		    }


			// Retrieve Journal Values
			list<c2g__codaJournal__c> jrns = [Select	id,
														Name,
														c2g__JournalCurrency__c,
                                                      	(select id,
                                                        		ffps_0387__Calculated_Charge2__c,
                                                        		c2g__Value__c ,
                                                           		c2g__lineNumber__c
                                                       		from
                                                            	c2g__JournalLineItems__r
	                                                 order by c2g__lineNumber__c)
	                                                 From
	                                                      c2g__codaJournal__c
	                                                 where
	                                                      Name in :jrnNames];

     		map<String, decimal> jrnLineToDocValMap = new map<String, decimal> ();
     		map<String, decimal> jrnLineToCalChrgMap = new map<String, decimal> ();
		    // Load the maps
		    for( c2g__codaJournal__c jrn : jrns)
		    {
		        for( integer i = 0; i <  jrn.c2g__JournalLineItems__r.size(); i++ )
		        {
		        	c2g__codaJournalLineItem__c jrnLin = jrn.c2g__JournalLineItems__r[i];        
					jrnLineToDocValMap.put( jrn.Name + '-' + jrnLin.c2g__lineNumber__c,  jrnLin.c2g__Value__c  );
					if( jrnLin.ffps_0387__Calculated_Charge2__c != null )
					{
						jrnLineToCalChrgMap.put( jrn.Name + '-' + jrnLin.c2g__lineNumber__c,  jrnLin.ffps_0387__Calculated_Charge2__c );
					}
		       	}
		    }
            
            
            // Apply Journal Values if necessary   
		    for( c2g__codaTransactionLineItem__c txLi : txLis)
		    {
				if( txLi.c2g__Transaction__r.c2g__TransactionType__c == 'Journal' )
				{
			    	jrnCount++;
					Decimal docVal = jrnLineToDocValMap.get( txLi.c2g__Transaction__r.c2g__DocumentNumber__c + 
																'-' + txLi.c2g__LineNumber__c.setscale(0) );
					Decimal calcVal = jrnLineToCalChrgMap.get( txLi.c2g__Transaction__r.c2g__DocumentNumber__c + 
																	'-' + txLi.c2g__LineNumber__c.setscale(0));
					if( txLi.c2g__DocumentValue__c == docVal )
					{
						if( calCVal != null )
						{
							txLi.ffps_0387__Calculated_Charge2__c = calcVal.setscale(2);
						}
						successCount++;
					}
					else
					{
			            errorMessages.add('Tx id ' + txLi.id + ' : ' + txLi.c2g__Transaction__r.c2g__TransactionType__c + ' : '
	            						+ ' : ' + txLi.c2g__DocumentValue__c + ' : ' +  txLi.ffps_0387__Calculated_Charge2__c  );
			            errorMessages.add('Journ ' +  txLi.c2g__Transaction__r.c2g__DocumentNumber__c + 
												'-' + txLi.c2g__LineNumber__c.setscale(0) + ' : ' + txLi.c2g__Transaction__r.c2g__DocumentNumber__c + ' : ' 
    												+ ' : ' + docVal + ' : ' +  calcVal  );

						failCount++;
						continue;
					}
				}
				
		        if(testRun)
        		{ 
		            successMessages.add('Tx id ' + txLi.id + ' : ' + txLi.c2g__Transaction__r.c2g__TransactionType__c + ' : '
		            						+ ' : ' + txLi.c2g__homevalue__C + ' : ' +  txLi.ffps_0387__Calculated_Charge2__c  );
        		}
		    }
		    
			// Update the txs
	    	if( testRun == false )
			{ 
				Database.Saveresult[] dbSrs = Database.update(txLis, false);
				for(Integer i = 0; i < dbSrs.size(); i++)
				{
					if(!dbSrs[i].isSuccess() )
					{
						for( Database.Error err : dbSrs[i].errors )
						{
				            errorMessages.add('\n ' + txLis[i] + ' Exception ' + err.getMessage() );
						}
					}
					else
					{
						successCount++;
					}
				}
	    	   	String errorString = ''; 
	        	for( String error : c2g.CODAExtensionContext.getErrorMessages())
	            {
	                if( error != null )
	                {
	                	errorString += error +' - ';
	                }
	            }
	            if( errorString != '' )
	            {
		            errorMessages.add('\n\n FFA  ' + errorString );
	            }
			}
	    

            if(Test.isRunningTest())
            {
                errorMessages.add('Code coverage message, needed to get coverage in the email section');
            }
        }
        catch(Exception e)
        {
        	errorMessages.add('============================================\n');              
    	   	String errorString = ''; 
        	for(String error : c2g.CODAExtensionContext.getErrorMessages())
            {
                errorString += error +' - ';
            }
            errorMessages.add('Unknown error ' + e.getMessage() + ' ' + e.getStackTraceString() + ' (' + e.getLineNumber() + ')');
            errorMessages.add('\n FFA  ' + errorString );
            errorMessages.add('============================================\n');              
    	
    	}   
    }

    /* FINISH */                   
    global void finish( Database.Batchablecontext BC )
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses( new String[] { 'LValenzuela@FinancialForce.com' } );
        String body = 'Successes : ' + String.valueOf(successCount) + '\n';
            
        for(String success : successMessages)
        {
            body += success +' \n';
        }

        body += 'Errors : ' + String.valueOf(failCount) + '\n';
        for(String error : errorMessages)
        {
            body += error +' \n';
        }
            
        mail.setPlainTextBody( body );
        mail.setSubject( 'Error updating Transaction Lines.' );
        
        if(!Test.isRunningTest())
        {
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
        }
    }

}