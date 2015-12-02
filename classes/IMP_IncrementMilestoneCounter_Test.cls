/*------------------------------------------------------------
Author: Alexander Daria
Company: Cloud Sherpas
Description: Test class for IMP_IncrementActivityOrMilestone_Handler
Test Class:
History
09/17/14    Alexander Daria     Created
11/19/14    Samuel Oberes       Implemented IMP_TestFactory_Helper methods
                                Fixed assertions for Planned_Start_Dt_Delayed_Count__c and Planned_End_Dt_Delayed_Count__c
------------------------------------------------------------*/
@isTest
public class IMP_IncrementMilestoneCounter_Test {
    static testMethod void ValidateMilestoneDatesDelayedCounter()  {

        // --------------------------------------------------------------------
        // INITIALIZATION 
        Project__c project = IMP_TestFactory_Helper.buildProject(0);
        insert project;
        
        SubProject__c subProject = IMP_TestFactory_Helper.buildSubProject(project.Id);
        insert subProject;
        
        Project_Milestone__c milestone = IMP_TestFactory_Helper.buildMilestoneNonStandard(subProject.Id, 'test');
        insert milestone;
        
        date initialPlannedStartDate = date.newInstance(2015, 10, 15);
        date initialPlannedEndDate   = date.newInstance(2015, 10, 16);

        date lessThanInitialPlannedStartDate = date.newInstance(2015, 10, 01);
        date lessThanInitialPlannedEndDate   = date.newInstance(2015, 10, 02);
        
        date greaterThanInitialPlannedStartDate = date.newInstance(2015, 10, 27);
        date greaterThanInitialPlannedEndDate   = date.newInstance(2015, 10, 28);
        
        Project_Activity__c projectActivity = IMP_TestFactory_Helper.buildProjectActivity(milestone.Id);
        projectActivity.Planned_Start_Date__c = initialPlannedStartDate;
        projectActivity.Planned_End_Date__c   = initialPlannedEndDate;
        insert projectActivity;
        
        // --------------------------------------------------------------------
        // TESTING PROPER

        Test.startTest();

        // 1) Insertion of project activity does not affect the project milestone's Planned_Start_Dt_Delayed_Count__c and/or Planned_End_Dt_Delayed_Count__c.
        //    Expect the mentioned fields to be null.
        Project_Milestone__c milestoneTesting = new Project_Milestone__c();
        milestoneTesting = [SELECT Planned_Start_Dt_Delayed_Count__c,
                                   Planned_End_Dt_Delayed_Count__c
                              FROM Project_Milestone__c
                             WHERE Id = :milestone.Id];

        System.assertEquals(null, milestoneTesting.Planned_Start_Dt_Delayed_Count__c);
        System.assertEquals(null, milestoneTesting.Planned_End_Dt_Delayed_Count__c);


        // 2) Planned_Start_Dt_Delayed_Count__c and/or Planned_End_Dt_Delayed_Count__c will only get updated if the new Planned_Start_Date__c and/or new Planned_end_Date__c
        //    will be greater than the old. Insert the same values upon update and expect the delayed counters to still be null.
        projectActivity.Department__c = 'Accounting';
        projectActivity.Planned_Start_Date__c = initialPlannedStartDate;
        projectActivity.Planned_End_Date__c   = initialPlannedEndDate;
        update projectActivity;
        
        milestoneTesting = [SELECT Planned_Start_Dt_Delayed_Count__c,
                                   Planned_End_Dt_Delayed_Count__c
                              FROM Project_Milestone__c
                             WHERE Id = :milestone.Id];
        
        System.assertEquals(null, milestoneTesting.Planned_Start_Dt_Delayed_Count__c);
        System.assertEquals(null, milestoneTesting.Planned_End_Dt_Delayed_Count__c);


        // 3) Entering Planned_Start_Date__c and Planned_End_Date__c values less than the present value will not affect the delay counters. Expect them still to be null.
        projectActivity.Planned_Start_Date__c = lessThanInitialPlannedStartDate;
        projectActivity.Planned_End_Date__c   = lessThanInitialPlannedEndDate;
        update projectActivity;
        
        milestoneTesting = [SELECT Planned_Start_Dt_Delayed_Count__c,
                                   Planned_End_Dt_Delayed_Count__c
                              FROM Project_Milestone__c
                             WHERE Id = :milestone.Id];
        
        System.assertEquals(null, milestoneTesting.Planned_Start_Dt_Delayed_Count__c);
        System.assertEquals(null, milestoneTesting.Planned_End_Dt_Delayed_Count__c);


        // 4) Entering Planned_Start_Date__c and Planned_End_Date__c values greater than the present value will now affect the delay counters. Expect them to get incremented by 1.
        projectActivity.Planned_Start_Date__c = greaterThanInitialPlannedStartDate;
        projectActivity.Planned_end_Date__c   = greaterThanInitialPlannedEndDate;
        update projectActivity;
        
        milestoneTesting = [SELECT Planned_Start_Dt_Delayed_Count__c,
                                   Planned_End_Dt_Delayed_Count__c
                              FROM Project_Milestone__c
                             WHERE Id = :milestone.Id];
        
        System.assertEquals(1, milestoneTesting.Planned_Start_Dt_Delayed_Count__c);
        System.assertEquals(1, milestoneTesting.Planned_End_Dt_Delayed_Count__c);
        
        
        Test.stopTest();
    }
}