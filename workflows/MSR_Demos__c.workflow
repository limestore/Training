<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>DS_Solution_Consultant_Presentation</fullName>
        <description>DS_Solution_Consultant_Presentation</description>
        <protected>false</protected>
        <recipients>
            <recipient>cameron.wong@cdk.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Inside_Sales/Solution_Consultant_Presentation_Survey1</template>
    </alerts>
    <alerts>
        <fullName>DS_Solution_Consultant_Presentation_Email_Alert</fullName>
        <description>DS_Solution_Consultant_Presentation_Email_Alert (Using WF)</description>
        <protected>false</protected>
        <recipients>
            <field>Opportunity_Owner_Field__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>SC_Manager_Field__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <recipient>cameron.wong@cdk.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Inside_Sales/Solution_Consultant_Presentation_Survey1</template>
    </alerts>
    <fieldUpdates>
        <fullName>LotManagementDate_Update</fullName>
        <field>Lot_Management_Date__c</field>
        <formula>Today()</formula>
        <name>LotManagementDate_Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>ServiceEdgeDate_Update</fullName>
        <field>ServiceEdge_Date__c</field>
        <formula>Today()</formula>
        <name>ServiceEdgeDate_Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Upd_LotManagementDateUnchecked</fullName>
        <field>Lot_Management_Date__c</field>
        <name>Upd_LotManagementDateUnchecked</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Upd_ServiceEdgeDateUnchecked</fullName>
        <field>ServiceEdge_Date__c</field>
        <name>Upd_ServiceEdgeDateUnchecked</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>DS_Solution_Consultant_Presentation</fullName>
        <actions>
            <name>DS_Solution_Consultant_Presentation</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>MSR_Demos__c.Account_Name__c</field>
            <operation>equals</operation>
            <value>Cobalt Sandbox eCare</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>DS_Solution_Consultant_Presentation_Created</fullName>
        <actions>
            <name>DS_Solution_Consultant_Presentation_Email_Alert</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>MSR_Demos__c.Was_this_job_a_shadow__c</field>
            <operation>equals</operation>
            <value>No</value>
        </criteriaItems>
        <criteriaItems>
            <field>MSR_Demos__c.Should_survey_be_sent__c</field>
            <operation>equals</operation>
            <value>Yes</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Upd_SolutionConsultantPresentation_LotManagementDate_Unchecked</fullName>
        <actions>
            <name>Upd_LotManagementDateUnchecked</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MSR_Demos__c.Lot_Management__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Upd_SolutionConsultantPresentation_LotManagement_Checked</fullName>
        <actions>
            <name>LotManagementDate_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MSR_Demos__c.Lot_Management__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Upd_SolutionConsultantPresentation_ServiceEdgeDate_Checked</fullName>
        <actions>
            <name>ServiceEdgeDate_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MSR_Demos__c.ServiceEdge__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Upd_SolutionConsultantPresentation_ServiceEdgeDate_Unchecked</fullName>
        <actions>
            <name>Upd_ServiceEdgeDateUnchecked</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MSR_Demos__c.ServiceEdge__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>