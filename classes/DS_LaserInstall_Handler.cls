public class DS_LaserInstall_Handler 
{
    public static void QueryChildRecordsForUpdate(map<ID, Laser_Install__c> newMap, map<ID, Laser_Install__c> oldMap)
    {
        boolean GreenLight = false;
        
        set<ID> LiIDset = new set<ID>();
        
        if(newMap != null && !newMap.isEmpty())
        {
            for(Laser_Install__c li: newMap.values())
            {
                if(li.LIN_Status__c != null && li.LIN_Status__c.toLowerCase() == 'installed')
                {
                    GreenLight = true;
                    LiIDset.add(li.ID);
                }
            }
        }
        
        map<ID, Laser_Install__c> LaserInstallWithChildRecords;
        
        if(GreenLight && !LiIDset.isEmpty())
        {
            LaserInstallWithChildRecords = new map<ID, Laser_Install__c>([
                Select Id, Name, 
                      (Select Id, Name, Installed_Date__c 
                       From Non_EFD_Lasers__r)
                From Laser_Install__c 
                Where ID IN :LiIDset
            ]);
        }
        
        map<ID, EFD_Lasers__c> EfdUpdateMap = new map<ID, EFD_Lasers__c>();
        
        if(LaserInstallWithChildRecords != null && !LaserInstallWithChildRecords.isEmpty())
        {
            for(Laser_Install__c li: LaserInstallWithChildRecords.values())
            {
                if(LiIDset.contains(li.ID))
                {
                    list<EFD_Lasers__c> EFDLasers = li.getSobjects('Non_EFD_Lasers__r');
                    
                    if(EFDLasers != null && !EFDLasers.isEmpty())
                    {
                        for(EFD_Lasers__c efd: EFDLasers)
                        {
                            efd.Installed_Date__c = Date.Today();
                            EfdUpdateMap.put(efd.ID, efd);
                        }
                    }
                }
            }
        }
        
        if(EfdUpdateMap != null && !EfdUpdateMap.isEmpty()){ Update EfdUpdateMap.values();}
    }
}