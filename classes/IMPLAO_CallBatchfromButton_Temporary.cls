global with sharing class IMPLAO_CallBatchfromButton_Temporary {
	
	webService static void callBatchfromButton()
	{
		CronTrigger cronJobCheck;
		boolean runBatch = true;
		list<CronTrigger> cronCheckList = new list<CronTrigger>();
		cronCheckList = [Select Id from CronTrigger where CronJobDetail.Name = 'Temporary Call for ProjectActivityBatch' limit 1];
		
		if(cronCheckList.size() > 0)
		{
			cronJobCheck = cronCheckList[0];
			runBatch = false;
		}
		
		if(runBatch)
		{
			callMe();
		}
		else
		{
			if(cronJobCheck!=null)
			{
				system.abortJob(cronJobCheck.Id);
				callMe();
			}
			
		}
	}
	
	global static void callMe()
	{
		IMP_ProjectActivityCapture_Batch scheduleBatchForLaser = new IMP_ProjectActivityCapture_Batch();
		string jobName = 'Temporary Call for ProjectActivityBatch';
		Id newJobId = system.scheduleBatch(scheduleBatchForLaser, jobName, 1);
		system.debug(newJobId);
	}

}