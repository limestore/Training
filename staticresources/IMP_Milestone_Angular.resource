var myApp = angular.module("myApp", []);

myApp.controller('setupPage',function($scope,$q, $window) {
    $scope.disable = { Milestone:false, Activity:false, Task:false, selectedRecord:0 };
    $scope.expand = { Child:false, GrandChild:false,expandChildCount:0, expandGrandChildCount:0 };
    $scope.createTaskHeader = false;
    $scope.permission = { edit: false, add:false, delete:false }; 
    $scope.showExpand = true;
    $scope.showLoadingScreen = true;
    var getURLParam = function ( name, url ) {
        if (!url) url = location.href;
        name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
        var regexS = "[\\?&]"+name+"=([^&#]*)";
        var regex = new RegExp( regexS );
        var results = regex.exec( url );
        return results == null ? null : results[1];
    }
    //get the current user id
    var userId = sforce.connection.getUserInfo().userId;
    var getUserPermission = function (sObjectType, permissionType) {
        var deferred = $q.defer();
       
        var loadPermission = function(queryResult) {                  
            deferred.resolve(JSON.stringify(queryResult));  
        }
        
        var callback = {                   
            onSuccess: loadPermission,
            onFailure: queryFailed
        };
        
        sforce.connection.query(
            "SELECT AssigneeId, Assignee.Name, PermissionSet.Id, PermissionSet.isOwnedByProfile, PermissionSet.Profile.Name, PermissionSet.Label \
                FROM PermissionSetAssignment WHERE AssigneeId ='" + userId + "'  \
                AND PermissionSetId IN (SELECT ParentId FROM ObjectPermissions WHERE SObjectType = '" +sObjectType + "' AND " + permissionType + " = true)",
            callback);
        
        function queryFailed(error) {
            console.log(error);
        }
        return deferred.promise;
    }
    getUserPermission('Project_Milestone__c', 'PermissionsEdit').then(function(data) {  
        $scope.permission.edit = JSON.parse(data).size == 0 ? false : true;            
        getUserPermission('Project_Activity__c', 'PermissionsEdit').then(function(data) {  
            $scope.permission.edit = JSON.parse(data).size == 0 ? false : true;  
            getUserPermission('Project_Activity__c', 'PermissionsCreate').then(function(data) {  
                $scope.permission.add = JSON.parse(data).size == 0 ? false : true;         
            });
        });
    });
    
    getUserPermission('Project_Task__c', 'PermissionsDelete').then(function(data) {  
        $scope.permission.delete = JSON.parse(data).size == 0 ? false : true;   
        if ($scope.permission.delete) {
            getUserPermission('Project_Activity__c', 'PermissionsDelete').then(function(data) {  
                $scope.permission.delete = JSON.parse(data).size == 0 ? false : true;  
                if ($scope.permission.delete) {
                    getUserPermission('Project_Milestone__c', 'PermissionsDelete').then(function(data) {  
                        $scope.permission.delete = JSON.parse(data).size == 0 ? false : true;            
                    });
                }
            }); 
        }                    
    });
    
    $scope.subprojectId = getURLParam('id', location.search);
    function loadMilestone() {
        var deferred = $q.defer();
       
        var miletoneLoad = function(queryResult) {                  
            deferred.resolve(JSON.stringify(queryResult));  
        }

        Visualforce.remoting.Manager.invokeAction(
            'IMP_MiletoneView_V2_Controller.getSubProjectMilestones',$scope.subprojectId,miletoneLoad                                        
        ); 

        return deferred.promise;
    }
    var promise = loadMilestone();
    promise.then(function(data) {  
        $scope.Subprojects = JSON.parse(data);   
        $scope.showLoadingScreen = false;
    });
    
    $scope.refresh = function() {         
        $scope.showLoadingScreen = true;
        loadMilestone().then(function(data) {
            $scope.errorMsgList = [];
            $scope.disable = { Milestone:false, Activity:false, Task:false, selectedRecord:0 };
            $scope.expand = { Child:false, GrandChild:false,expandChildCount:0, expandGrandChildCount:0 };
            $scope.Subprojects = JSON.parse(data);
            $scope.showLoadingScreen = false;
        });
    }
    
    $window.afRenderPage = function() {      
        $scope.showLoadingScreen = true;
        $scope.errorMsgList = [];
        loadMilestone().then(function(data) {
            expandIds = [];
            angular.forEach($scope.Subprojects, function(milestone) {              
                if (milestone.expandChild) {
                    expandIds.push(milestone.obj.Id);
                }       
            });
            $scope.Subprojects = JSON.parse(data);  
            addExpandAndErrorInTheList([],expandIds);
            $scope.disable = { Milestone:false, Activity:false, Task:false, selectedRecord:0 };
            $scope.showLoadingScreen = false;
        });
    }
    
    $scope.disableCheckbox = function(section,value) {  
        //disable the checkbox for the other section, only the checkbox in the same section must be enable
        $scope.disable.Milestone = section == 'Milestone' ? false : true;
        $scope.disable.Activity = section == 'Activity' ? false : true;
        $scope.disable.Task = section == 'Task' ? false : true;
        //monitor the number of record selected, if there are no more selected/check record, enable all checkbox
        $scope.disable.selectedRecord = value ? $scope.disable.selectedRecord + 1 : $scope.disable.selectedRecord -1;
        if ($scope.disable.selectedRecord == 0) {
            $scope.disable.Milestone = false;
            $scope.disable.Activity = false;
            $scope.disable.Task = false;
        }
    }
    
    var validateDelete = function(recordsToValidate,skipCheck) {
        var cnt=0;
        var valid = true;        
        if (!skipCheck) {
            angular.forEach(recordsToValidate, function(record) { 
                //first condition is for the task record, the second condition for the activity, 
                //in the activity condition, check first if the 'record' has 'activity' object before getting the value of 'toDelete' so it will not throw an error that
                //'toDelete' is undefined
                if (record.toDelete || (record.activity && record.activity.toDelete)) {                    
                    cnt++;
                }
            });
            if (cnt == recordsToValidate.length) {
                valid = false;
            }
        }
        return valid;
    }  
        
    var executeDelete = function(idsToDelete) {
        var deferred = $q.defer();
        deferred.resolve(sforce.connection.deleteIds([idsToDelete]));
        return deferred.promise
    }
    
    var createHierarchy = function() {
        var milestoneRecords = [];
        var cntMiles = -1;
        var cntAct = -1;       
        var milestone = { projectMilestone: {}, projectActivity:[] };     
        var activity = { activity: {}, projectTask:[] };
        
        angular.forEach($scope.Subprojects, function(rec) {
            if (rec.section == 'Milestone') {
                milestone.projectMilestone = rec;
                milestoneRecords.push(milestone);
                milestone = { projectMilestone: {}, projectActivity:[]};
              
                cntMiles++;                
                cntAct = -1;             
            } else if (rec.section == 'Activity') {
                activity.activity = rec;
                milestoneRecords[cntMiles].projectActivity.push(activity);
                activity = { activity: {}, projectTask:[] };
                cntAct++;               
            } else {
                milestoneRecords[cntMiles].projectActivity[cntAct].projectTask.push(rec);              
            }
        });
        return milestoneRecords;
    }
    $scope.deleteMilestone = function() {   
        $scope.showLoadingScreen = true;
        $scope.errorMsgList = [];
        var Subprojects =  createHierarchy();
        var deleteMilestoneObj = new Array();
        var deleteActivityObj = new Array();
        var deleteTaskObj = new Array();
        var expandIds = [];
        var errorList = [];
        var hasCheckRecord = false;
        //get all the ids that is for deletion
       angular.forEach(Subprojects, function(milestone) {
            var activityForceDelete = false;
            if (milestone.projectMilestone.toDelete) {
                deleteMilestoneObj.push(milestone.projectMilestone.obj.Id);
                //force the child (activity and task) to be included in the list to be deleted if the parent is subproject for deletion
                activityForceDelete = true;
                hasCheckRecord = true
            }
           
            if (milestone.projectMilestone.expandChild) {
                expandIds.push(milestone.projectMilestone.obj.Id);
            }
            if(validateDelete(milestone.projectActivity,activityForceDelete)) {
                angular.forEach(milestone.projectActivity, function(activity) {
                    var taskForceDelete = false;
                   
                    if (activityForceDelete || activity.activity.toDelete) {
                        deleteActivityObj.push(activity.activity.obj.Id);
                        //force the child (task) to be included in the list to be deleted if the parent is subproject for deletion
                        taskForceDelete = true;
                        hasCheckRecord = true;
                    }
                    if (activity.activity.expandGrandChild) {
                        expandIds.push(activity.activity.obj.Id);
                    }
                    if(validateDelete(activity.projectTask,taskForceDelete)) {
                        angular.forEach(activity.projectTask, function(tasks) {                            
                            if (taskForceDelete || tasks.toDelete) {
                                // var tsk = new sforce.SObject("Project_Task__c");
                                deleteTaskObj.push(tasks.obj.Id);
                                hasCheckRecord = true;
                            }
                        });
                    } else {     
                        hasCheckRecord = true;
                        errorList.push(activity.activity.obj.Id);                        
                        $scope.errorMsgList.push('Milestone: ' + milestone.projectMilestone.obj.Description__c + ', Activity: ' + activity.activity.obj.Description__c + '- Cannot delete selected Task, Activity should have at least 1 Task');
                    }
                });
            } else {
                hasCheckRecord = true;
                errorList.push(milestone.projectMilestone.obj.Id);              
                $scope.errorMsgList.push('Milestone: ' + milestone.projectMilestone.obj.Description__c + '- Cannot delete selected Activity, Milestone should have at least 1 Activity');
            }
       });
        
        //execute the delete call, the task should be the first to delete 
        if (deleteMilestoneObj.length != 0 || deleteTaskObj.length != 0 || deleteActivityObj.length != 0) {
            $scope.showLoadingScreen = false;
            var message = confirm("Are you sure?");
            if (message) {
                $scope.showLoadingScreen = true;
                setTimeout(function() {
                    executeDelete(deleteTaskObj).then(function(data) {
                        errorList.push.apply( errorList, getRecordsError(deleteTaskObj,data) ) ;
                        //delete the activity
                        executeDelete(deleteActivityObj).then(function(data) {
                            errorList.push.apply( errorList, getRecordsError(deleteActivityObj,data) ) ;
                            //delete the milestone
                            executeDelete(deleteMilestoneObj).then(function(data) {
                                errorList.push.apply( errorList, getRecordsError(deleteMilestoneObj,data) ) ;
                                //reload the data and highlight the row that contains error/fail after deleting
                                loadMilestone().then(function(data) {
                                    $scope.Subprojects = JSON.parse(data);    
                                    addExpandAndErrorInTheList(errorList,expandIds);
                                    $scope.disable = { Milestone:false, Activity:false, Task:false, selectedRecord:0 };
                                    $scope.showLoadingScreen = false;
                                });
                            });
                        });
                    });
                }, 100);
            }
        } else if (!hasCheckRecord) {
             $scope.errorMsgList.push('No record selected for deletion. Please select any record in the table');
            $scope.showLoadingScreen = false;
        } else {
            //Has selected record but not valid for deletion, highlight the row that contains the error
            addExpandAndErrorInTheList(errorList,expandIds);
            $scope.showLoadingScreen = false;
        }
    }
    
    var getRecordsError = function(recordList,errorList) {
        var errorObject = [];                        
        if (errorList) {
            for(var cnt=0;cnt < errorList.length; cnt++) {
                if (!errorList[cnt].getBoolean("success")) {                  
                    var err = recordList[cnt].Id ? recordList[cnt].Id : recordList[cnt]; 
                    errorObject.push(err);
                    $scope.errorMsgList.push(errorList[cnt].errors.message);
                }
            }
        }                 
        return errorObject;
    }
    
    var addExpandAndErrorInTheList = function(errorIdList,expandIdList) {
        var parentId = '', childId = '';      
        angular.forEach($scope.Subprojects, function(milestone) {
            var listContainsErrorId = errorIdList != '' ? (errorIdList.indexOf(milestone.obj.Id) > -1) :  false;
            milestone.hasError = listContainsErrorId;          
            if (milestone.section == 'Milestone') {
                milestone.expandChild = expandIdList != '' ? (expandIdList.indexOf(milestone.obj.Id) > -1) :  false;  
                parentId= '';
                if(milestone.expandChild) {                   
                    parentId = milestone.obj.Id;
                }                
            } else if (milestone.section == 'Activity') {
                childId = '';      
                milestone.expandChild = expandIdList != '' ? (expandIdList.indexOf(milestone.obj.Id) > -1) :  false;  
                if (milestone.expandChild) {
                    childId = milestone.obj.Id;
                    milestone.expandGrandChild = true;
                }                       
                if (parentId == milestone.parentId) {                    
                    milestone.expandChild = true;                    
                }
            } else {
                if (childId == milestone.parentId) {
                    milestone.expandGrandChild = true;
                }
            }
        });                    
    }
    
    var executeUpdate = function(recordToUpdate) {
        var deferred = $q.defer();
        deferred.resolve(sforce.connection.update(recordToUpdate));
        return deferred.promise
    }
    
    $scope.UpdateDisplayPSR = function(psrValue) {
        $scope.showLoadingScreen = true;        
        var updateMilestoneObj = new Array();
        var updateActivityObj = new Array();
        var updateTaskObj = new Array();
        $scope.errorMsgList = [];
        var expandIds = [];
        
        angular.forEach($scope.Subprojects, function(milestone) {            
            if (milestone.section == "Milestone") {
                var miles = new sforce.SObject("Project_Milestone__c");                
                miles.Id = milestone.obj.Id;
                miles.Display_on_PSR__c = psrValue;   
                updateMilestoneObj.push(miles);
            }            
            if (milestone.section == 'Activity') {
                var act = new sforce.SObject("Project_Activity__c");
                act.Id = milestone.obj.Id;
                act.Display_on_PSR__c = psrValue;                
                updateActivityObj.push(act);          
            }            
            if (milestone.section == 'Task') {
                var tsk = new sforce.SObject("Project_Task__c");
                tsk.Id = milestone.obj.Id;
                tsk.Display_on_PSR__c = psrValue;                                
                updateTaskObj.push(tsk);
            }
            if ((milestone.section == "Milestone" && milestone.expandChild) || 
                (milestone.section == 'Activity' && milestone.expandGrandChild)) {
                expandIds.push(milestone.obj.Id);
            }
        });
        var errorList = [];
             
        setTimeout(function() {
            executeUpdate(updateTaskObj).then(function(data) {
                errorList.push.apply( errorList, getRecordsError(updateTaskObj,data) ) ;                  
                executeUpdate(updateActivityObj).then(function(data) {
                    errorList.push.apply( errorList, getRecordsError(updateActivityObj,data) ) ;                   
                    executeUpdate(updateMilestoneObj).then(function(data) {
                        errorList.push.apply( errorList, getRecordsError(updateMilestoneObj,data) ) ;                                        
                        loadMilestone().then(function(data) {                      
                            $scope.Subprojects = JSON.parse(data);                        
                            addExpandAndErrorInTheList(errorList,expandIds);
                            $scope.disable = { Milestone:false, Activity:false, Task:false, selectedRecord:0 };
                            $scope.showLoadingScreen = false;
                        });
                    });
                });
            });
        }, 100);
    }
    
    $scope.toggleRecord = function(record,section) {        
        //show the excess column
        if (section == 'Activity') {
            $scope.expand.Child = true;
            $scope.expand.expandChildCount = record.expandChild ? $scope.expand.expandChildCount + 1 : $scope.expand.expandChildCount -1;            
        }        
        if (section == 'Task') {
            $scope.expand.GrandChild = true;
            $scope.expand.expandGrandChildCount = record.expandGrandChild ? $scope.expand.expandGrandChildCount + 1 : $scope.expand.expandGrandChildCount -1;
        }
        var parentActivityId = '';
        var updateTaskCount = false;
        angular.forEach($scope.Subprojects, function(milestone) {      
            if (milestone.parentId == parentActivityId && !record.expandChild && milestone.expandGrandChild && updateTaskCount) {
                //this will handle the count of the task if the selected milestone is change from expand to collapse
                //without this, the excess column will not hide even if there are no more expanded task
                $scope.expand.expandGrandChildCount = $scope.expand.expandGrandChildCount -1;
                updateTaskCount = false;
            }
            //this will make the child record to appear if the parent is expanded
            if (milestone.parentId == record.obj.Id) {    
                if (milestone.section == 'Activity') {
                    milestone.expandChild = record.expandChild;         
                    parentActivityId = milestone.obj.Id;
                    updateTaskCount = true;
                    milestone.expandGrandChild = false;
                } else if (milestone.section == 'Task') {                    
                    milestone.expandGrandChild = record.expandGrandChild;
                } 
            }
            //this will hide the grandchild if the parent is change from expand to collapse
            if (milestone.parentId == parentActivityId && !record.expandChild) {               
                milestone.expandGrandChild = false;
            }            
        }); 
        //this will remove the excess column if there are no more activity expanded
        if($scope.expand.expandGrandChildCount == 0) {
             $scope.expand.GrandChild = false;
        }
        //this will remove the excess column if there are no more milestone expanded
        if($scope.expand.expandChildCount == 0) {
             $scope.expand.Child = false;
        }      
    }
    
    $scope.toggleAllRecord = function(behavior) {       
        $scope.showExpand = !behavior;
        $scope.expand.GrandChild = behavior; 
        $scope.expand.Child = behavior; 
        $scope.expand.expandChildCount = 0;
        $scope.expand.expandGrandChildCount = 0
        angular.forEach($scope.Subprojects, function(milestone) {            
            milestone.expandChild = behavior; 
            milestone.expandGrandChild = behavior;
            if (milestone.section == 'Milestone' && behavior) {              
                $scope.expand.expandChildCount = $scope.expand.expandChildCount + 1;            
            }        
            if (milestone.section == 'Activity' && behavior) {               
                $scope.expand.expandGrandChildCount = $scope.expand.expandGrandChildCount + 1;
            }
        });       
    }
    
    $scope.showWindowPop = function(url,paramaters,width,height) {
		window.open(url + '?subProjectId=' + $scope.subprojectId + paramaters, 'windowPopup','location=1,status=1,scrollbars=1,resizable=1, width=' + width + ',height=' + height);
	}
    
    $scope.goToEditPage = function() {
        window.open('/apex/ALL_RecordsView?id='+ $scope.subprojectId +'&key=Milestone', '_self');
    }
})

