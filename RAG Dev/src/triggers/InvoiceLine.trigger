trigger InvoiceLine on c2g__codaInvoiceLineItem__c (before insert) 
{
	set<id> invoiceIds = new set<id>();
	list<c2g__codaInvoiceLineItem__c> existingLines = new list<c2g__codaInvoiceLineItem__c>();
	map<id, boolean > invoiceToLinesEqualMap = new map<id, boolean >();  
	map<id, id> invoiceToDim1Map = new map<id, id>();  
	map<id, id> invoiceToDim2Map = new map<id, id>();  
	map<id, id> invoiceToDim3Map = new map<id, id>();  
	
	for(c2g__codaInvoiceLineItem__c line : trigger.new)
	{
		invoiceIds.add(line.c2g__Invoice__c);
	}	

	existingLines = [select id, 
							c2g__Invoice__c, 
							c2g__Dimension1__c,
							c2g__Dimension1__r.id,
							c2g__Dimension2__c,
							c2g__Dimension2__r.id,
							c2g__Dimension3__c,
							c2g__Dimension3__r.id
						from
							c2g__codaInvoiceLineItem__c
						where
							c2g__Invoice__c in :invoiceIds];	


	for(c2g__codaInvoiceLineItem__c line : existingLines)
	{
		if( invoiceToLinesEqualMap.get(line.c2g__Invoice__c) == null  )
		{
			// intiate equal flag
			invoiceToLinesEqualMap.put(line.c2g__Invoice__c , true);
		}

		/* Dimension 1 (Practice) */				
		if( line.c2g__Dimension1__c != null 
			&& invoiceToDim1Map.get(line.c2g__Invoice__c) != null
				&& invoiceToDim1Map.get(line.c2g__Invoice__c) != line.c2g__Dimension1__c)
		{
			// set flag to state that lines are not equal
			invoiceToLinesEqualMap.put(line.c2g__Invoice__c , false);
		}
		else if( invoiceToDim1Map.get(line.c2g__Invoice__c) == null )
		{
			// If no line has been set then intiate first one.
			invoiceToDim1Map.put(line.c2g__Invoice__c, line.c2g__Dimension1__c);
		}

		/* Dimension 2 (Group) */				
		if( line.c2g__Dimension2__c != null 
			&& invoiceToDim2Map.get(line.c2g__Invoice__c) != null
				&& invoiceToDim2Map.get(line.c2g__Invoice__c) != line.c2g__Dimension2__c)
		{
			// set flag to state that lines are not equal
			invoiceToLinesEqualMap.put(line.c2g__Invoice__c , false);
		}
		else if( invoiceToDim2Map.get(line.c2g__Invoice__c) == null )
		{
			// If no line has been set then intiate first one.
			invoiceToDim2Map.put(line.c2g__Invoice__c, line.c2g__Dimension2__c);
		}

		/* Dimension 3 (Project) */				
		if( line.c2g__Dimension3__c != null 
			&& invoiceToDim3Map.get(line.c2g__Invoice__c) != null
				&& invoiceToDim3Map.get(line.c2g__Invoice__c) != line.c2g__Dimension3__c)
		{
			// set flag to state that lines are not equal
			invoiceToLinesEqualMap.put(line.c2g__Invoice__c , false);
		}
		else if( invoiceToDim3Map.get(line.c2g__Invoice__c) == null )
		{
			// If no line has been set then intiate first one.
			invoiceToDim3Map.put(line.c2g__Invoice__c, line.c2g__Dimension3__c);
		}
	}
	
	
	// If all lines with a value agree then assign the dims to lines without values.
	for(c2g__codaInvoiceLineItem__c line : trigger.new)
	{
		if( invoiceToLinesEqualMap.get(line.c2g__Invoice__c) == true )
		{
			line.c2g__Dimension1__c = (line.c2g__Dimension1__c == null ? invoiceToDim1Map.get(line.c2g__Invoice__c) : line.c2g__Dimension1__c) ;
			line.c2g__Dimension2__c = (line.c2g__Dimension2__c == null ? invoiceToDim2Map.get(line.c2g__Invoice__c) : line.c2g__Dimension2__c) ;
			line.c2g__Dimension3__c = (line.c2g__Dimension3__c == null ? invoiceToDim3Map.get(line.c2g__Invoice__c) : line.c2g__Dimension3__c) ;
		}
	}
}