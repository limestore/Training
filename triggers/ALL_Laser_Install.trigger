trigger ALL_Laser_Install on Laser_Install__c (before insert, before update, after insert, after update)
{
    if((Trigger.isInsert && Trigger.isAfter) || (Trigger.isUpdate && Trigger.isbefore))
    {
        DS_LaserInstall_Handler.QueryChildRecordsForUpdate(Trigger.newMap, Trigger.OldMap);
    }
    
}