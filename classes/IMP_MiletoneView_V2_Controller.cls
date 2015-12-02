global class IMP_MiletoneView_V2_Controller 
{  
    public static List<Project_Milestone__c> retrieveMilestoneRecords(String subId)
    {
        //Retrieve related milestones 
        String milestoneOrderQuery = IMP_Project_Utility.getOrderColumns(SObjectType.Project_Milestone__c.FieldSets.Milestone_Sort_Commons.getFields(), true);
        String activityOrderQuery = IMP_Project_Utility.getOrderColumns(SObjectType.Project_Activity__c.FieldSets.Activity_Sort_Commons.getFields(), true);
       
        String query = 'SELECT Actual_End_Date__c, Actual_End_Date_Final__c,Actual_Start_Date__c, Comments__c, Risk_Gauge_Color__c, Account__c ,' +
            'Process_Step__c,External_System_Name__c, Description__c, Planned_End_Date__c, Planned_Start_Date__c, ' +
            'Site__c, Status__c, Id, External_System_ID__c,Standard__c,Sort_Sequence__c,' +
            '(SELECT Activity_Definition__c,Actual_End_Date__c,Actual_End_Date_Final__c,Actual_Start_Date__c,CDK_Assignee__r.Name, External_ID__c,' +
            'CDK_Assignee_Role__c,Client_Assignee__r.Name,Department__c,Description__c,Display_on_PSR__c, Risk_Gauge_Color__c,' +
            'Planned_End_Date__c,Planned_Start_Date__c,Status__c,Comments__c,Standard__c,Sequence__c  FROM Project_Activities__r ' + activityOrderQuery + ') ' +
            'FROM Project_Milestone__c where SubProject__c =: subId ' + milestoneOrderQuery;
        
        return Database.query(query);
    }
    
    public static Map<Id, List<Project_Task__c>> retrieveTaskRecords(String subId)
    {
        //for unknown reason the objectId is becoming 18 char id, need to get only 15 char id
        Map<Id, List<Project_Task__c>> completeTaskMap = new Map<Id, List<Project_Task__c>> ();
     
        subId = subId.substring(0, 15);
     
        String taskOrderQuery = IMP_Project_Utility.getOrderColumns(SObjectType.Project_Task__c.FieldSets.Task_Sort_Commons.getFields(), true);
        
        String query = 'SELECT Project_Activity__c,Task_Definition__c,Actual_End_Date__c,Actual_Start_Date__c,CDK_Assignee__r.Name, External_ID__c, Expected_Time_Spent__c,' +
            'CDK_Assignee_Role__c,Client_Assignee__r.Name,Description__c,Display_on_PSR__c, Actual_Time_Spent__c, Reason__c,  Migration_Status__c, Reason_Missed_Planned_End_Date__c ,' +
            'Planned_End_Date__c,Planned_Start_Date__c,Status__c,Comments__c,Standard__c,Sequence__c  FROM Project_Task__c where SubProject_ID__c = : subId ' + taskOrderQuery;
        
        List<Project_Task__c> taskList = Database.query(query);
        
        //link the activity and the project task
        for (Project_Task__c tsk : taskList)
        {
            if (completeTaskMap.containsKey(tsk.Project_Activity__c))
            {
                //add the task in the existing activity
                //this automatically update the value in the completeTaskMap no need to re update the map
                List<Project_Task__c> tskList = completeTaskMap.get(tsk.Project_Activity__c);
                tskList.add(tsk);
            }
            else
            {
                List<Project_Task__c> tskList = new List<Project_Task__c> ();
                tskList.add(tsk);
                completeTaskMap.put(tsk.Project_Activity__c, tskList);
            }
        }
        
        return completeTaskMap;
    }
  
    @RemoteAction
    global static List<MilestoneWrapper> getSubProjectMilestones(String SubprojectId)
    {
        List<Project_Milestone__c> projectMilestones = retrieveMilestoneRecords(SubprojectId);
        Map<Id, List<Project_Task__c>> completeTaskMap = retrieveTaskRecords(SubprojectId);
        system.debug('projectMilestones' + projectMilestones.size());
        //populate the record in wrapper
        List<MilestoneWrapper> milestoneContentList = new List<MilestoneWrapper> ();
        for (Project_Milestone__c miles : projectMilestones)
        {
            MilestoneWrapper mWrapper = new MilestoneWrapper();
            mWrapper.obj = miles;
            //site have a different way to highlight in the field
            //it needs to be in a list of string
           
            mWrapper.toDelete = false;
            mWrapper.expandChild = false;
            mWrapper.section = 'Milestone';
            milestoneContentList.add(mWrapper);
            //populate the activity and add in the milestone
            if (miles.Project_Activities__r != null)
            {
                for (Project_Activity__c act : miles.Project_Activities__r)
                {
                    MilestoneWrapper aWrap = new MilestoneWrapper();
                    aWrap.obj = act;
                    aWrap.expandGrandChild = false;
                    aWrap.section = 'Activity';
                    aWrap.parentId = miles.Id;
                    milestoneContentList.add(aWrap);
                    //populate the task and add in the activity
                    if (completeTaskMap.containsKey(act.id))
                    {
                        List<Project_Task__c> taskList = completeTaskMap.get(act.id);
                        Boolean createHeader = true;
                        for (Project_Task__c t : taskList)
                        {
                            MilestoneWrapper tWrap = new MilestoneWrapper();
                            tWrap.obj = t;
                            tWrap.toDelete = false;
                            tWrap.hasError = false;
                            tWrap.section = 'Task';
                            tWrap.createHeader = createHeader;
                            tWrap.parentId = act.id;
                            milestoneContentList.add(tWrap);
                            createHeader = false;
                        }
                    }
                }
            }
        }
       
        return milestoneContentList;
    }
    
    global class MilestoneWrapper
    {
        public SObject obj { get; set; }       
        public Boolean expandChild { get; set; }     
        public Boolean expandGrandChild { get; set; }     
        public Boolean toDelete { get; set; }
        public Boolean hasError { get; set; }
        public Boolean createHeader { get; set; }
        public String section { get; set; }       
        public String parentId { get; set; }
    }
}