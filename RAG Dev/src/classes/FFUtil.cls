/*
 * Copyright (c) FinancialForce.com inc 
 * All rights reserved.
*/
public with sharing class FFUtil 
{   
    /**
     * Due Date Rules
     **/
    public static String BASE_DATE_END_OF_NEXT_MONTH = 'End of next month';
    public static String BASE_DATE_START_OF_NEXT_MONTH = 'Start of next month';
    public static String BASE_DATE_INVOICE_DATE = 'Invoice date';
    
    /**
     * Special Periods
     **/
    public static final String OPENING_PERIOD = '000';
    public static final String ADJUSTMENT_PERIOD = '100';
    public static final String CLOSING_PERIOD = '101';  
    
    public static Boolean TEST_MODE = false;
    
    // Simple cache of the users current company (do not directly expose this partially loaded object)
    private static c2g__codaCompany__c s_currentCompany;
    private static c2g__codaAccountingCurrency__c s_currentCompanyHomeCurrency;  
    private static List<c2g__codaPeriod__c> s_currentCompanyPeriods;
    private static Boolean s_multiCurrencyOrganization = UserInfo.isMultiCurrencyOrganization();
    
    /**
     * Resolve current company for current user
     **/
    public static c2g__codaCompany__c getCurrentCompany()
    {
        // Cached resulted from previous call?
        if(s_currentCompany!=null)
            return s_currentCompany;
            
        // Query users group membership and xref with companies to determine current subscription
        List<ID> groupIds = new List<ID>();
        for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()])
            groupIds.add(member.GroupId);               
        c2g__codaCompany__c[] companies = 
            [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
        
        // Ensure the user has a single current company
        if(companies.size() == 0)
            throw new FFUtilException('Current company has not been set for this user');
        if(companies.size() > 1)
            throw new FFUtilException('This operation is not valid in multiple company mode'); 
        s_currentCompany = companies[0];
        
        // Load Periods for this company
        s_currentCompanyPeriods = 
            [select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c, c2g__Closed__c from c2g__codaPeriod__c where c2g__OwnerCompany__c = :s_currentCompany.Id];
                            
        return s_currentCompany;
    }
    
    /**
     * Resolve periods for the current company
     **/
    public static List<c2g__codaPeriod__c> getPeriods()
    {
        c2g__codaCompany__c company = getCurrentCompany();
        return s_currentCompanyPeriods;
    }
    
    /**
     * Returns true if the current users company tax mode is VAT
     *   (errors if no current company or multiple company mode enabled for the user)
     **/ 
    public static boolean isCurrentCompanyVAT()
    {   
        return getCurrentCompany().RecordType.Name.equals('VAT');       
    }

    /**
     * Returns true if the current users company tax mode is SUT
     *   (errors if no current company or multiple company mode enabled for the user)
     **/ 
    public static boolean isCurrentCompanySalesAndUse()
    {   
        return getCurrentCompany().RecordType.Name.equals('SUT');       
    }
    
    /**
     * Returns the ID for the default company Tax Code
     **/
    public static ID getDefaultCompanyTaxCode()
    {
        return getCurrentCompany().c2g__TaxCode__c;
    }
    
    /**
     * Return true if the org is setup for Salesforce Multicurrency
     **/
    public static Boolean isMultiCurrencyOrganization() 
    {
        if( TEST_MODE )
        {
            return !s_multiCurrencyOrganization;
        }
        return s_multiCurrencyOrganization;
    }
    
    public static String getAccountCurrencyIsoCode( Id accountId )
    {
        String query = 'select id, CurrencyIsoCode from account where Id=:accountId limit 1';
        if( !FFUtil.isMultiCurrencyOrganization() )
            query = 'select id from account where Id=:accountId limit 1';
        
        return FFUtil.getAccountCurrencyIsoCode( (Account)Database.query( query ) );
    }
    
    /**
     * Returns the current companies home currency ISO code
     **/
    public static String getAccountCurrencyIsoCode(Account account)
    {
        // For multi-currency orgs we use the standard Saleforce field
        if (isMultiCurrencyOrganization())  
            return (String) account.get('CurrencyIsoCode'); // Uses Dynamic Apex to avoid package dependency            
        // Load Home currency for this company (only one per company allowed)
        if(s_currentCompanyHomeCurrency==null)
        {
            c2g__codaAccountingCurrency__c[] accountCurrencies = 
                [select Id, Name from c2g__codaAccountingCurrency__c where c2g__Home__c = true and c2g__OwnerCompany__c = :getCurrentCompany().Id];
            if(accountCurrencies.size()==0)
                throw new FFUtilException('Current company does not have a home accounting currency defined');
            s_currentCompanyHomeCurrency = accountCurrencies[0];
        }         
        // For none multi-currency orgs, use the current companies Home currency
        return s_currentCompanyHomeCurrency.Name;
    }
    
    /**
     * Returns the applicable period for the given date?
     **/
    public static ID getPeriodIDByDate(Date periodDate)
    {
        for(c2g__codaPeriod__c queryPeriod : getPeriods())
        {
            if((queryPeriod.c2g__StartDate__c <= periodDate) &&
               (queryPeriod.c2g__EndDate__c >= periodDate) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(OPENING_PERIOD) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(ADJUSTMENT_PERIOD) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(CLOSING_PERIOD))
                return queryPeriod.Id;
        }
        return null;
    }
    
    /**
     * Returns the applicable period for the given date?
     **/
    public static Date getPeriodStartDate(Date periodDate)
    {
        for(c2g__codaPeriod__c queryPeriod : getPeriods())
        {
            if((queryPeriod.c2g__StartDate__c <= periodDate) &&
               (queryPeriod.c2g__EndDate__c >= periodDate) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(OPENING_PERIOD) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(ADJUSTMENT_PERIOD) &&
               !queryPeriod.c2g__PeriodNumber__c.equals(CLOSING_PERIOD))
                return queryPeriod.c2g__StartDate__c;
        }
        return null;
    }

    /**
     * Sets a test company and periods (for use during Apex Unit tests only)
     **/    
    public static void setTestCompany(c2g__codaCompany__c company, c2g__codaAccountingCurrency__c accountingCurrency)
    {
        s_currentCompany = company;
        s_currentCompanyPeriods = 
            [select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c from c2g__codaPeriod__c where c2g__OwnerCompany__c = :s_currentCompany.Id];
        s_currentCompanyHomeCurrency = accountingCurrency;
    }
    
    /**
     * Sets the test mode to multi or single currency
     **/
    public static void setTestMultiCurrencyOrganization(Boolean multiCurrencyOrganization)
    {
        s_multiCurrencyOrganization = multiCurrencyOrganization;
    }

    /**
     * General exceptions from this class
     **/    
    public class FFUtilException extends Exception
    {
        
    }
    
    @isTest (seeAllData = true)
    public static void testFFUtil()
    {
        FFUtil ffu = new FFUtil();
        FFUtil.getCurrentCompany();
        
        String query = 'select id, CurrencyIsoCode from account limit 1';
        if( !FFUtil.isMultiCurrencyOrganization() )
            query = 'select id from account limit 1';
        
        FFUtil.getAccountCurrencyIsoCode( ((Account)Database.query( query )).Id );
        FFUtil.getPeriodStartDate(date.newInstance( 2010, 1, 1 ));
        FFUtil.getDefaultCompanyTaxCode();
        FFUtil.isCurrentCompanyVAT();
        FFUtil.isCurrentCompanySalesAndUse();
        FFUtil.getPeriodIDByDate( date.newInstance( 2012, 1, 1 ) );
        
        TEST_MODE = true;
        query = 'select id, CurrencyIsoCode from account limit 1';
        if( !FFUtil.isMultiCurrencyOrganization() )
            query = 'select id from account limit 1';
        FFUtil.getAccountCurrencyIsoCode( ((Account)Database.query( query )).Id );
    }
    
}