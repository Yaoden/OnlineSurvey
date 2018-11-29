<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>SendExamtoContact</fullName>
        <description>Send Exam to Contact</description>
        <protected>false</protected>
        <recipients>
            <field>Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>OnlineSurveyProject/ExamResponseContactTemplate</template>
    </alerts>
    <alerts>
        <fullName>SendSurveytoContact</fullName>
        <description>Send Survey to Contact</description>
        <protected>false</protected>
        <recipients>
            <field>Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>OnlineSurveyProject/SurveyResponseContactTemplate</template>
    </alerts>
</Workflow>
