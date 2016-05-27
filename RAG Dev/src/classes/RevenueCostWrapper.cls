// Externalised for use in changes made by CD0387
public class RevenueCostWrapper 
{
    public String role{get;set;}
    public Decimal hourlyRate{get;set;}
    public Decimal costRate{get;set;}
    public Decimal totalHoursPerRole{get;set;}
    public Decimal costPerRole{get; set;}
    public Decimal revenuePerRole{get; set;}

    public RevenueCostWrapper(String role, Decimal estRevPerRole, Decimal estCostPerRole, Decimal totalHoursPerRole) 
    {
        this.role = role;
        this.hourlyRate = (estRevPerRole / totalHoursPerRole).setScale(2); // hourly revenue per role
        this.costRate = (estCostPerRole / totalHoursPerRole).setScale(2); // hourly cost per role
        this.totalHoursPerRole = totalHoursPerRole.setScale(2);
        this.costPerRole = estCostPerRole.setScale(2); // total cost per role
        this.revenuePerRole = estRevPerRole.setScale(2); // total revenue per role
    }
}