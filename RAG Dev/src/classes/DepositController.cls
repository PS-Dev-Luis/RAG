public with sharing class DepositController 
{
    public string DateFormat { get; set; }
    public string locale { get; set; }

    public class AppException extends Exception {}

    public class SearchResult
    {
        public string RecordId { get; set; }
        public string Name { get; set; }
        public string Info { get; set; }
    }

    public class Journal
    {
        public string JournalDate { get; set; }
        public string GLAId { get; set; }
        public string BankAccountId { get; set; }
        public List<JournalLine> Lines { get; set; }
    }

    public class JournalLine
    {
        public string ReceivedFromId { get; set; }
        public string AccountId { get; set; }
        public string Description { get; set; }
        public string PaymentMethod { get; set; }
        public string RefNo { get; set; }
        public decimal Amount { get; set; }
        public string ProductId { get; set; }
        public string Dim1Id { get; set; }
    }

    public DepositController()
    {
        DateFormat = LocaleHelper.getDateFormat();
        locale = UserInfo.getLocale().subString( 0, 2 );
    }

    @RemoteAction
    public static List<SearchResult> autocompleteAccount( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( Account acc : [Select Id, Name from Account where Name like :query limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = acc.Id;
            res.Name = acc.Name;
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static List<SearchResult> autocompleteGLA( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( c2g__codaGeneralLedgerAccount__c acc : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where Name like :query limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = acc.Id;
            res.Name = acc.Name;
            res.Info = acc.c2g__ReportingCode__c;
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static List<SearchResult> autocompleteProduct( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( Product2 prod : [Select Id, 
                                     Name, 
                                     ProductCode,
                                     ( Select Pricebook2Id, UnitPrice From PricebookEntries) 
                                 From Product2 
                                where Name like :query limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = prod.Id;
            res.Name = prod.Name;
            
            
            for( PricebookEntry pbe : prod.PricebookEntries)
            {
                res.Info = String.valueOf(pbe.UnitPrice);
            }
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static List<SearchResult> autocompleteProduct2( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( Product2 prod : [Select Id, Name, ProductCode from Product2 where Name like :query and IsActive = true limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = prod.Id;
            res.Name = prod.Name;
            res.Info = prod.ProductCode;
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static List<SearchResult> autocompleteDimension1( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( c2g__codaDimension1__c dim : [Select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c where Name like :query limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = dim.Id;
            res.Name = dim.Name;
            res.Info = dim.c2g__ReportingCode__c;
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static List<SearchResult> autocompleteBankAccount( string terms )
    {
        List<SearchResult> results = new List<SearchResult>();
        string query = '%' + terms + '%';
        for( c2g__codaBankAccount__c bank : [Select Id, Name, c2g__AccountName__c from c2g__codaBankAccount__c where Name like :query limit 20] )
        {
            SearchResult res = new SearchResult();
            res.RecordId = bank.Id;
            res.Name = bank.Name;
            res.Info = bank.c2g__AccountName__c;
            results.add( res );
        }

        return results;
    }

    @RemoteAction
    public static SearchResult findGLAForBankAccount( string bankId )
    {
        SearchResult result = null;
        List<c2g__codaBankAccount__c> bank = [Select Id, c2g__GeneralLedgerAccount__c, c2g__GeneralLedgerAccount__r.Name, c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c from c2g__codaBankAccount__c where Id = :bankId];
        if( bank.size() > 0 && bank[0].c2g__GeneralLedgerAccount__c != null )
        {
            result = new SearchResult();
            result.RecordId = bank[0].c2g__GeneralLedgerAccount__c;
            result.Name = bank[0].c2g__GeneralLedgerAccount__r.Name;
            result.Info = bank[0].c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c;
        }

        return result;
    }

    @RemoteAction
    public static SearchResult createJournal( Journal rawJournal )
    {
    	return null;
    }
}