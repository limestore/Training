public with sharing class IMP_UpdateAnsCompletedOfAnswerCategories 
{
	public static void updateAnsCompletedOnAnswerCategories(map<Id, boolean> anyAnswerValueMap)
	{
		list<Discovery_Answer_Workbook_Category__c> answerCategoriesToUpdate = new list<Discovery_Answer_Workbook_Category__c>();
		if(!anyAnswerValueMap.keySet().isEmpty())
		{
			list<Discovery_Answer_Workbook_Category__c> listToProcess= [
			select Answer_Completed__c, Answer__c from Discovery_Answer_Workbook_Category__c where
			Answer__c IN:anyAnswerValueMap.keySet()];
			for(Discovery_Answer_Workbook_Category__c dawc:listToProcess)
			{
                system.debug('--Discovery Answers-----'+anyAnswerValueMap.get(dawc.Answer__c));
				dawc.Answer_Completed__c = anyAnswerValueMap.get(dawc.Answer__c);
				answerCategoriesToUpdate.add(dawc);
			}
			if(!answerCategoriesToUpdate.isEmpty())
			{
				try { update answerCategoriesToUpdate; }
				catch (Exception e){System.debug(e);}
			}
			 
		}
		
		
	}

}