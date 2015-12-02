public class CB_UpdateAccountPlanFields 
{
    public static void updateAccountPlan(map<ID, WebId__c> newMap, map<ID, WebId__c> oldMap)
    {
        //logic added for RQ-05402
        
        list<WebId__c> WebIDsChanged = new list<WebId__c>();
        set<string> fieldSet = new set<string>{ 'LMA_Analyst__c', 'LMA_Analyst2__c', 'LMA_Strategist__c' };
       
        for(webId__c w: newMap.values())
        {
            boolean filedsForCurrentWebIdChanged = false;
            filedsForCurrentWebIdChanged = ALL_UtilitiesLogic.compareNewAndOldTriggerValues(fieldSet, w, oldMap.get(w.ID));
            
            system.debug(filedsForCurrentWebIdChanged);
            
            if(filedsForCurrentWebIdChanged)
            {
                WebIDsChanged.add(w);
            }
        }
        
        if(!WebIDsChanged.isEmpty())
        {
            list<Account_Plan__c> APlist = new list<Account_Plan__c>([
                Select Id, WebId__c From Account_Plan__c 
                Where WebId__c 
                IN : WebIDsChanged
            ]);
            
            Database.update(APlist, false);
        }
    }
}