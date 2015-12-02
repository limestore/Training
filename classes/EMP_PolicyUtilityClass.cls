public class EMP_PolicyUtilityClass {
    @future
    public static void deletePolicyAcknowledgement(List<String> validEmployeeIds)
    {
        //List<User> validEmployee = new List<User>();
        List<EMP_Policy__c> deletePolicyList = new List<EMP_Policy__c>();
        List<EMP_Policy__c> policyList = [select id,Acknowledgement_Status__c from EMP_Policy__c where User_Name__c IN :validEmployeeIds];
        if(!policyList.isEmpty())
        {
            for(EMP_Policy__c empPolicy: policyList)
            {
                if(empPolicy.Acknowledgement_Status__c==false)
                {
                    deletePolicyList.add(empPolicy);
                }
            }
            delete deletePolicyList;
        }        
    }
    
    @future
    public static void createNewContactAndPolicy(List<Id> userIdsForContact,List<Id> userIdsForPolicy)
    {
        //this below block is used to create a new contact when a user is created
        if(!userIdsForContact.isEmpty())
        {
            List<User> users = [select id,name,Title,Email,FirstName,LastName from User where Id IN :userIdsForContact];
            List<Contact> newContactsToInsert = new List<Contact>();
            //Get the default account id that will be used in creating contact
            CustomSettings__c mc = CustomSettings__c.getOrgDefaults();
            
            Account a = null;
            List<Account> accts = [
                select id 
                from Account 
                where id = :mc.CDK_Global_Account_Id__c 
                limit 1
            ];
            if(accts != null && !accts.isEmpty()) { a = accts.get(0); }
            
            if(a != null)
            {
                for(User usr : users)
                {
                    Contact con = new Contact();
                    con.AccountId = a.Id;
                    con.Status__c = 'Active';
                    con.Title = usr.Title;
                    con.Email = usr.Email;
                    con.User__c = usr.id;
                    con.FirstName = usr.FirstName;
                    con.LastName = usr.LastName;
                    newContactsToInsert.add(con);
                }
            }
            
            if(!newContactsToInsert.isEmpty())
            {
                insert newContactsToInsert;
            }
        }
        
        //this below block is used to create necessary policies when a user is created
        if(!userIdsForPolicy.isEmpty())
        {
            List<User> validEmployee = new List<User>();
            List<EMP_Policy__c> insertPolicy = new List<EMP_Policy__c>();
            validEmployee = [select id,name,Title,Email,FirstName,LastName from User where Id IN :userIdsForPolicy];
            List<EMP_Policy__c> policyList = [select id,Acknowledgement_Status__c,Name,User_Name__c from EMP_Policy__c where User_Name__c IN :userIdsForPolicy];
            List<ContentVersion> lstContentVersion = getAllPolicyLatestDocument();
            insertPolicy = generatePolicyAcknowledgement(validEmployee,lstContentVersion);
            insertPolicy = uniquePolicies(policyList,insertPolicy);
            if(!insertPolicy.isEmpty())
            {
                insert insertPolicy;
            }  
        }
        
    }
    
    //This method eliminates policies which are already assigned to a user
    public static List<EMP_Policy__c> uniquePolicies(List<EMP_Policy__c> existingPolicies,List<EMP_Policy__c> duplicatePolicies)
    {
        for(Integer i=0;i<existingPolicies.size();i++)
        {
            EMP_Policy__c existingPolicy = existingPolicies.get(i);
            for(Integer j=0;j<duplicatePolicies.size();j++)
            {                
                EMP_Policy__c duplicatePolicy = duplicatePolicies.get(j);
                if(existingPolicy.Name==duplicatePolicy.Name && existingPolicy.User_Name__c==duplicatePolicy.User_Name__c)
                {
                    duplicatePolicies.remove(j);                  
                }
            }
        }        
        return duplicatePolicies;
    }
    
    public static List<ContentVersion> getAllPolicyLatestDocument() 
    {
        //this method is used in getting the content in the policy content library
        List<ContentDocument> contentDocuments = getPolicyContentDocument();
        //get the valid content record for the policy acknowledgement
        List<ContentVersion> contentVersionObj = [Select Title,Id,VersionNumber,Policy_Effective_Date__c From ContentVersion where ContentDocumentId in: contentDocuments and Acknowledgement_Required__c = true
                                                  and Expiration_Date__c > TODAY 
                                                  and Geographic_Applicability__c = 'Global'];
        //change list to map for easy manipulation
        Map<Id,ContentVersion> contentVersions = mapContentVersion(contentVersionObj);
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        for(ContentDocument contentDoc : contentDocuments)
        {
            //check if the content document is valid for the policy acknowledgement
            if (contentVersions.containsKey(contentDoc.LatestPublishedVersionId))
            {
                ContentVersion latestContent = contentVersions.get(contentDoc.LatestPublishedVersionId);
                lstContentVersion.add(latestContent);
            }
        }
        
        return  lstContentVersion;                                            
    }
    
    public static List<ContentDocument> getPolicyContentDocument() 
    {
        //this method will get the record for the policy
        String PolicyName = System.Label.EMP_Policy_Name;
        List<ContentDocument> contentDocuments = [SELECT Title,  PublishStatus,  ParentId, OwnerId,  Id, LatestPublishedVersionId
                                                  FROM ContentDocument
                                                  WHERE ParentId IN: [SELECT Id 
                                                                      FROM ContentWorkspace 
                                                                      WHERE Name = :PolicyName] ];
        return  contentDocuments;                                             
    }
    
    private static Map<id,ContentVersion> mapContentVersion(List<ContentVersion> contents)
    {
        Map<id,ContentVersion> contentVersion = new Map<id,ContentVersion>();
        for(ContentVersion content : contents)
        {
            contentVersion.put(content.Id, content);
        }
        return contentVersion;
    }
    
    public static List<EMP_Policy__c> generatePolicyAcknowledgement(List<User> users, List<ContentVersion> contentVersions)
    {
        //this method will insert policy acknowledgement for the list of users
        List<EMP_Policy__c> empPolicy = new List<EMP_Policy__c>();
        Map<Id,Id> mapAccountContact = getUserIdToContactIdMap(users);
        for (User usr : users)
        {
            Id contactId;
            //this method will get the contact for the user
            if (mapAccountContact.containsKey(usr.Id))
            {   
                contactId = mapAccountContact.get(usr.Id);
            }
            for (ContentVersion content : contentVersions)
            {
                EMP_Policy__c policy = new EMP_Policy__c();
                policy.User_Name__c = usr.Id;
                policy.Name = content.Title;
                policy.Content_Version_ID__c = content.Id;
                policy.VersionNumber__c = Integer.valueOf(content.VersionNumber);
                policy.Policy_Addition_Date__c = content.Policy_Effective_Date__c;              
                policy.Employee_Contact__c =contactId;
                empPolicy.add(policy);
            }
        }
        return empPolicy;
        
    }
    
    private static Map<Id,Id> getUserIdToContactIdMap(List<User> usrs)
    {
        List<Contact> contacts = [Select Id,Name,User__c From Contact where User__c in : usrs];
        Map<Id,Id> mapContactAndAccount = new Map<Id,Id>();
        for (Contact con : contacts)
        {           
            mapContactAndAccount.put(con.User__c, con.Id);            
        }
        return mapContactAndAccount;
    }
    
    public static void updateUserswithContactIds(List<Id> userIds, Map<Id,Id> userIdToContact)
    {
        //this method will update the contact field in the user object
        List<User> userToUpdate = new List<User>();
        List<User> retrieveUser = [Select Id, EMP_Contact__c from User where Id in : userIds];
        for (User u : retrieveUser)
        {
            Id contactId = userIdToContact.get(u.Id);
            u.EMP_Contact__c = String.valueOf(contactId);
            userToUpdate.add(u);
        }
        if(!userToUpdate.isEmpty())
        {
            update userToUpdate;
        }
    }
    
    public static Map<id,ContentDocument> mapContentDocument(List<ContentDocument> contents)
    {
        Map<id,ContentDocument> contentDocuments = new Map<id,ContentDocument>();
        for(ContentDocument content : contents)
        {
            contentDocuments.put(content.Id, content);
        }
        return contentDocuments;
    }
    
    public static Map<Id,Id> getPolicyReference()
    {
        //Get all the version id in the policy object
        List<Policy_Reference_Log__c> empPolicy = [Select Id,Policy_Id__c from Policy_Reference_Log__c ];
        List<Id> policyIds = new List<Id>();
        Map<Id,Id> mapParentId = new Map<Id,Id>();
        for(Policy_Reference_Log__c content : empPolicy)
        {
            if (!mapParentId.containsKey(content.Policy_Id__c))
            {
                mapParentId.put(content.Policy_Id__c, content.Policy_Id__c);
            }
        }
        return mapParentId;
    }
    
    public static List<User> getUserForAcknowledgement()
    {
        //this method will get all the valid user for the policy acknowledgement
        List<User> users = [SELECT Id,Name From User where Non_Employee__c = false and Contractor__c =  false and isActive = true and Non_Interactive_User__c = false ];
        return users;
    }
    
    public static void updatePolicyReference(List<ContentVersion> newPolicyCreated)
    {
        //this method will add the new created policy in the log, for reference 
        List<Policy_Reference_Log__c> toInsert = new List<Policy_Reference_Log__c>();
        for (ContentVersion content : newPolicyCreated)
        {
            Policy_Reference_Log__c ref = new Policy_Reference_Log__c();
            ref.Policy_Id__c = content.ContentDocumentId;
            toInsert.add(ref);
        }
        
        if(!toInsert.isEmpty())
        {
            Insert toInsert;
        }
    }
}