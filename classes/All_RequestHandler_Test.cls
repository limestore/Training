// Author : Lalitha Adduru
// Description : Test class for All_Request trigger

@isTest
public class All_RequestHandler_Test {
    public static testmethod void testRequestTrigger()
    {
        Request__c req = new Request__c(
                Name = 'TestDescription',
                Details__c='TestDetails',
                Business_Justification__c = 'TestJustification',
                Deployment_Strategy__c='In PROD Only',
                Status__c='Open',
                Internal_Priority__c='2 High', 
                Initial_Estimate__C= 12345,
                User_Groups_Impacted__c='CB - Finance'
            );
        insert req;        
        EntitySubscription follower = new EntitySubscription(ParentId = req.id , subscriberId = UserInfo.getUserId());
        insert follower;
        req.Name = 'TestDesriptionEdited';
        update req;
        //req.Status__c = 'Completed';
        
        //update req;       
    }
}