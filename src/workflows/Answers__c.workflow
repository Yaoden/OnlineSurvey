<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdateCorrectAnswer</fullName>
        <field>CorrectAnswer__c</field>
        <literalValue>1</literalValue>
        <name>Update Correct Answer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateIncorrectAnswer</fullName>
        <field>CorrectAnswer__c</field>
        <literalValue>0</literalValue>
        <name>Update Incorrect Answer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Check if Correct</fullName>
        <actions>
            <name>UpdateCorrectAnswer</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(SurveyResponse__r.Survey__r.RecordType.DeveloperName = &apos;Exam&apos;, Correct__c = True)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Check if Incorrect</fullName>
        <actions>
            <name>UpdateIncorrectAnswer</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(SurveyResponse__r.Survey__r.RecordType.DeveloperName = &apos;Exam&apos;, Correct__c = False)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
