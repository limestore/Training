trigger IMP_Answer on Answer__c (before update, after update, after insert)
{
    if(Trigger.isAfter)
    {
            if(Trigger.isUpdate)
            {
                system.debug('Testing');
                boolean oldValue;
                //set<Id> answerIdsToProcess = new set<Id>();
                map<Id, boolean> answerMapToProcess = new map<Id, boolean>();
                
                for(Answer__c ans:[select Id, Any_Answer__c, (select Id from Discovery_Answer_Workbook_Categories__r)
                                   from Answer__c where Id IN: Trigger.newMap.keySet()])
                {
                    
                    /*system.debug('--NewValue---'+ans.Any_Answer__c);
                    oldValue = Trigger.oldMap.get(ans.Id).Any_Answer__c;
                    system.debug('--OldValue---'+oldValue);
                    if(ans.Any_Answer__c != oldValue)
                    {*/
                    if(!ans.Discovery_Answer_Workbook_Categories__r.isEmpty())
                    {
                        answerMapToProcess.put(ans.Id, ans.Any_Answer__c);
                    }   
                    //}
                }
                if(!answerMapToProcess.keySet().isEmpty())
                {
                    //IMP_UpdateAnsCompletedOfAnswerCategories.updateAnsCompletedOnAnswerCategories(answerMapToProcess);
                }
             }
          
    }
    /*Pattern urlPattern = Pattern.compile('^(http[s]??://)?(www.)?(([a-zA-Z0-9[-][.]]+).[a-zA-Z0-9[-][.]]*[a-zA-Z0-9].[a-z]{3})(([/][a-zA-Z0-9[_][.]]+)*)?([?]([a-zA-Z0-9]+[=][a-zA-Z0-9]+)([&][&][a-zA-Z0-9]+[=][a-zA-Z0-9]+)*)?$');
    for(Answer__c answer: Trigger.New)
    {
        if(answer.Answer_Type__c!='URL' && !answer.N_A__c)
        {
            if(answer.URL_Answer__c!='' || answer.URL_Answer__c!=null)
            {
                Matcher urlMatcher = urlPattern.matcher(answer.URL_Answer__c);
                if(!urlMatcher.matches())
                {
                    answer.URL_Answer__c.addError('Not a valid URL');
                }
            }
        }
    }*/
}