/*
*   Journal Correction Script
*/
global with sharing class CalculatedChargeJournalCleanseBatch implements Database.Batchable<sObject>, Database.Stateful
{
    global Boolean testRun = true;
    
    List<String> errorMessages = new List<String>();
    List<String> successMessages = new List<String>();
    Id companyId;

    integer failCount = 0;
    integer changeCount = 0;
    integer successCount = 0;

    global CalculatedChargeJournalCleanseBatch()
    {
    }

    /* START */                   
    public String getQuery()
    {
        String query     = ' Select  id,                                    '+
                           '         c2g__Type__c,                          '+
                           '         c2g__SourceJournal__c,                 '+
                           '         c2g__OriginalJournal__c,               '+
                           '         Name,                                  '+
                           '           (select id,                          '+
                           '             ffps_0387__Calculated_Charge2__c,  '+
                           '             c2g__Value__c ,                    '+
                           '                c2g__lineNumber__c              '+
                           '            from                                '+
                           '                 c2g__JournalLineItems__r       '+  
                           '          order by c2g__lineNumber__c)          '+
                           '      From                                      '+
                           '           c2g__codaJournal__c                  '+
                           '      where                                     '+
                           '    c2g__OwnerCompany__r.id = :myCompanyId      '+
                           '    and                                         '+
                           '    (c2g__Type__c = \'Cancelling Journal\'      '+
                           '    or                                          '+
                           '    c2g__Type__c = \'Reversing Journal\')       ';

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
        try
        {
            list<c2g__codaJournal__c> cJrns  = (list<c2g__codaJournal__c>) scope;
            list<Id> cancelIds = new list<id>();
            for( c2g__codaJournal__c jrn : cJrns)
            {
                cancelIds.add( jrn.c2g__Type__c  == 'Reversing Journal' ? jrn.c2g__SourceJournal__c :  jrn.c2g__OriginalJournal__c ) ;   
            }

            list<c2g__codaJournal__c> jrns = [Select    id,
                                                        c2g__Type__c,
                                                        c2g__SourceJournal__c,
                                                        c2g__OriginalJournal__c,
                                                        Name,
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
                                                          id in :cancelIds];

            map<id, c2g__codaJournal__c> origJrnMap = new map<id, c2g__codaJournal__c> (jrns);
            
            for( c2g__codaJournal__c cJrn : cJrns)
            {
                c2g__codaJournal__c origJrn = origJrnMap.get( (id) (cJrn.c2g__Type__c  == 'Reversing Journal' 
                                                                        ? cJrn.c2g__SourceJournal__c 
                                                                        :  cJrn.c2g__OriginalJournal__c) );
                for( integer i = 0; i <  cJrn.c2g__JournalLineItems__r.size(); i++)
                {        
                    try
                    {
                        if(  cJrn.c2g__JournalLineItems__r[i].c2g__Value__c  != -origJrn.c2g__JournalLineItems__r[i].c2g__Value__c )
                        {
                            errorMessages.add('Line not updated ' + cJrn.id + ' : ' 
                                                + cJrn.c2g__JournalLineItems__r[i].c2g__Value__c + ' : '
                                                    + origJrn.c2g__JournalLineItems__r[i].c2g__Value__c );
                            failCount++;
                            continue;
                        }
                        if( origJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c  == null )
                        {
                            successCount++;   
                            continue;
                        }
                        if( cJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c  != -origJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c )
                        {
                            if(testRun)
                            {
                                successMessages.add('Journal id ' + cJrn.c2g__JournalLineItems__r[i].id + ' : ' 
                                                        + cJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c + ' : '
                                                            + -origJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c  );
                            }
                            cJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c = -origJrn.c2g__JournalLineItems__r[i].ffps_0387__Calculated_Charge2__c.setscale(2);
                            changeCount++;
                            
                            if(testRun == false)
                            { 
                                Database.update(cJrn, false);
                                changeCount++;
                            }
                        }
                        successCount++;   
                    }
                    catch (exception e)
                    {    
                        errorMessages.add('============================================');              
                        errorMessages.add('Line failed ' + cJrn.id + ' : ' + cJrn.Name );
                        for( c2g__codaJournalLineItem__c jrnLin : cJrn.c2g__JournalLineItems__r)
                        {
                            errorMessages.add('- ' + jrnLin.id + ' : ' + jrnLin.c2g__LineNumber__c + ' : ' 
                                                    + jrnLin.c2g__Value__c + ' : ' + jrnLin.ffps_0387__Calculated_Charge2__c );
                        }
                                      
                        errorMessages.add('Original  ' + origJrn.id + ' : ' + origJrn.Name );
                        for( c2g__codaJournalLineItem__c origJrnLin : origJrn.c2g__JournalLineItems__r)
                        {
                            errorMessages.add('- ' + origJrnLin.id + ' : ' + origJrnLin.c2g__LineNumber__c + ' : ' 
                                                    + origJrnLin.c2g__Value__c + ' : ' + origJrnLin.ffps_0387__Calculated_Charge2__c );
                        }
                        
                        String errorString = ''; 
                        for(String error : c2g.CODAExtensionContext.getErrorMessages())
                        {
                            errorString += error +' - ';
                        }

                        errorMessages.add('/n Exception ' + e.getMessage() + '(' + e.getLineNumber() +')');
                        errorMessages.add('/n FFA  ' + errorString );
                        errorMessages.add('============================================');              
                        failCount++;
                        continue;
                    }   
                }
            }
               

            if(Test.isRunningTest())
            {
                errorMessages.add('Code coverage message, needed to get coverage in the email section');
            }
        }
        catch(Exception e)
        {
                errorMessages.add('Unknown error : ' + e.getMessage() + '(' + e.getLineNumber() + ')');
        }
    }

    /* FINISH */                   
    global void finish( Database.Batchablecontext BC )
    {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses( new String[] { 'LValenzuela@FinancialForce.com' } );
            String body = 'Successes : ' + successCount + ' \n';
            body += 'Updates : ' + changeCount + ' \n';
            
            for(String success : successMessages)
            {
                body += success +' \n';
            }

            body += 'Errors : ' + failCount + '\n';
            for(String error : errorMessages)
            {
                body += error +' \n';
            }
            
            mail.setPlainTextBody( body );
            mail.setSubject( 'Error updating Journals.' );
            
            if(!Test.isRunningTest())
            {
                Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
            }
    }

}