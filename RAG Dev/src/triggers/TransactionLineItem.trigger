trigger TransactionLineItem on c2g__codaTransactionLineItem__c (before insert, after insert, after update) 
{
	// Disable functionality
	if(ConfigSettings.isCalcuateChargeOnTransaction_Disabled())
	return;
	
	map <id,c2g__codaTransactionLineItem__c> updateTxLis	= new map <id,c2g__codaTransactionLineItem__c>(); 
		
	for( c2g__codaTransactionLineItem__c txLi : trigger.new)
	{
		if(trigger.isBefore)
		{
			if( txLi.calculated_charge2__c == null )
			{
				if( txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.authSubFeeRepCode )
					||
					txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.authSubFeeInvNotRecRepCode )
					||
					txLi.c2g__GeneralLedgerAccount__c == GlSettings.rptToGlMap.get( GlSettings.actualSubFeeRepCode) )
				{
					txLi.calculated_charge2__c = txLi.c2g__homevalue__C * ( CustomSettings.subFeeMultiplier ); 
				}
				else
				{
					txLi.calculated_charge2__c = txLi.c2g__homevalue__C; 
				}
			}
		}
		
		
		if( txLi.calculated_charge2__c != null 
				&& 
				( ( trigger.isAfter && trigger.isInsert ) 
						|| 
				  ( trigger.isAfter && trigger.isUpdate && txLi.calculated_charge2__c != trigger.oldMap.get( txLi.id ).calculated_charge2__c )  
				  		||
				  	// only added to facilitate the updating of old data, so that calculated charges could be set without changing the value
				  	// this setting should be disabled for normal BAU processing.	
			  		( trigger.isAfter && trigger.isUpdate && ConfigSettings.isConvertCalcuatedChargeOnUpdate_Disabled() == false ) ) )
		{
			// Document Currency
			if( txLi.c2g__DocumentCurrency__c != null &&
					txLi.Calculated_Charge_DocCurrency__c != CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__DocumentCurrency__c ) ) 
			{
				if( updateTxLis.get(txLi.id) == null )
				{
					c2g__codaTransactionLineItem__c updateTx = new c2g__codaTransactionLineItem__c(id = txLi.id);
					updateTxLis.put(updateTx.id, updateTx);
				}
				
				updateTxLis.get(txLi.id).Calculated_Charge_DocCurrency__c = CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__DocumentCurrency__c ) ; 
			}
			
			// Dual Currency
			if( txLi.c2g__DualCurrency__c != null &&
					txLi.Calculated_Charge_DualCurrency__c != CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__DualCurrency__c ) ) 
			{
				if( updateTxLis.get(txLi.id) == null )
				{
					c2g__codaTransactionLineItem__c updateTx = new c2g__codaTransactionLineItem__c(id = txLi.id);
					updateTxLis.put(updateTx.id, updateTx);
				}
				
				updateTxLis.get(txLi.id).Calculated_Charge_DualCurrency__c = CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__DualCurrency__c ) ; 
			}
	
			// Dim3 Currency
			if( txLi.c2g__Dimension3Currency__c != null && 
					txLi.Calculated_Charge_Dim3Currency__c != CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__Dimension3Currency__c )) 
			{
				if( updateTxLis.get(txLi.id) == null )
				{
					c2g__codaTransactionLineItem__c updateTx = new c2g__codaTransactionLineItem__c(id = txLi.id);
					updateTxLis.put(updateTx.id, updateTx);
				}
				
				updateTxLis.get(txLi.id).Calculated_Charge_Dim3Currency__c = CurrencyHelper.convertFromHome( txLi.calculated_charge2__c, txLi.c2g__Dimension3Currency__c ) ; 
			}
		}
	}

		
	if( trigger.isAfter && updateTxLis != null && updateTxLis.size() > 0 )
	{
		update updateTxLis.values();
	}
}