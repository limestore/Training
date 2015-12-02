/*------------------------------------------------------------
Author:        Vishal Bandari
Description:   Test Class to Test DS_LaserInstall_Handler and ALL_Laser_Install Trigger
Created on:    2015-11-09.
Code Coverage: 100%
------------------------------------------------------------
History
2015-11-09    vishal.bandari@cdk.com        Created
------------------------------------------------------------*/
@Istest
public class DS_LaserInstall_Test 
{
    @testSetup
    static void setUptestData()
    {
        Laser_Install__c liObj = new Laser_Install__c();
        liObj.EFD_Last_Downloaded__c = Date.today();
        liObj.EFD_Lasers__c = 3.0;
        insert liObj;
        List<EFD_Lasers__c> efdList = new List<EFD_Lasers__c>();
        for(Integer i=0;i<3;i++)
        {
            EFD_Lasers__c efdObj = new EFD_Lasers__c();
            efdObj.Laser_Install__c = liobj.Id;
            efdList.add(efdObj);
        }
        insert efdList;
    }
    
    static testmethod void validateHandler()
    {
        Laser_Install__c liObj = [SELECT Id, LIN_Status__c FROM Laser_Install__c Order by CreatedDate desc LIMIT 1];
        liObj.LIN_Status__c = 'Installed';
        update liObj;
        List<EFD_Lasers__c> efdLaserList = [
            SELECT Id 
            FROM EFD_Lasers__c 
            WHERE Laser_Install__c =: liObj.Id
            AND Installed_Date__c =: Date.Today()
        ];
        System.assertEquals(efdLaserList.size(),3,'All EFD_Lasers__c are not updated');
    }
}