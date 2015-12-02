global class UpdateSubproject implements Database.Batchable<sobject>
{
    global Database.QueryLocator start(Database.BatchableContext info)
    {
        return Database.getQueryLocator('select id from subproject__c');
    }
    global void execute(Database.BatchableContext info, List<sObject> scope)
    {
        update scope;
    }
      
    
    global void finish(Database.batchableContext info)
    {
        System.debug('Done Batches');
    }

}