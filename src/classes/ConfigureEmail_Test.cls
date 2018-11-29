@isTest
public class ConfigureEmail_Test {
    
    
    /*
     * Creates survey objects, survey/question junction objects, and question objects for test
     * 
     * If setup fails, that means there is an issue with the data model.
     * 
     */ 
    @TestSetup static void setup(){
        
        
        List<Question__c> lstQues = new List<Question__c>();
        List<SurveyJoinQuestion__c> listJunc = new List<SurveyJoinQuestion__c>();
        
        /*
         * Creates two test contacts: one to be emailed and one to be deleted 
         */
        Contact testUser = new Contact(FirstName='test',LastName='user',email='testuser@test.com');
        insert testUser;
        
        testUser = new Contact(FirstName='delete',LastName='me',email='deleteme@test.com');
        insert testUser;        

        /*
         * Creates test survey
         */ 
        
		Survey__c surv = new Survey__c(name='test survey' ,RecordTypeId=Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId());
        insert surv;
        
        
        
        /*
         * Creates a Survey response object
         */
        
        SurveyResponse__c resp = new SurveyResponse__c(Survey__c = surv.id, Contact__c = testUser.id);
        insert resp;
        
        /*
         * Create four questions true/false,radio button, open ended, and multiple choice
         */
        
        //true or false
        Question__c testQuestion = new Question__c(
    		RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId(),
    		Questionfor__c = 'Survey',
            Question_Text__c='True or false question');
        lstQues.add(testQuestion);
        
        //radio button
        testQuestion = new Question__c(
            RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId(),
            Questionfor__c = 'Survey',
            Question_Text__c='Radio button question',
            Choice_A__c = 'Choice A',
            Choice_B__c = 'Choice B',
            Choice_C__c = 'Choice C',
            Choice_D__c = 'Choice D',
            Choice_E__c = 'Choice E'); 
		lstQues.add(testQuestion);
        
        //open ended
        testQuestion = new Question__c(
            RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Short Answer').getRecordTypeId(),
            Questionfor__c = 'Survey',
            Question_Text__c='Short answer question');
		lstQues.add(testQuestion);
        
        //multiple choice
        testQuestion = new Question__c(
            RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId(),
            Questionfor__c = 'Survey',
            Question_Text__c='Multiple Choice question',
            Choice_A__c = 'Choice A',
            Choice_B__c = 'Choice B',
            Choice_C__c = 'Choice C',
            Choice_D__c = 'Choice D',
            Choice_E__c = 'Choice E');
    	lstQues.add(testQuestion);
        
        insert lstQues;
        
        /*
         * Create junction object for survey and question
         */ 
        for(integer i = 0;i < lstQues.size();i++){
            listJunc.add(new SurveyJoinQuestion__c(Survey__c=surv.id,Question__c=lstQues[i].id));
        }
        
        insert listJunc;
         
    }
    
    /*
     * Test method that tests the ConfigureEmail Visualforce page and controller
     */ 
    
    @isTest
    public static void testEmailConfigController(){
        
        //Creates a new page reference that references the ConfigureEmail visualforce page
        Pagereference pref = Page.ConfigureEmail;
        Test.setCurrentPage(pref);
        
        //Creates the standardsetcontroller object for the controller
        List<Contact> lstTestUsers = [Select Id,Name from Contact]; 
        Survey__c survey = [select id,name from Survey__c where name = 'test survey' limit 1]; 
        ApexPages.StandardSetController emailSSC = new ApexPages.StandardSetController(lstTestUsers);
        emailSSC.setSelected(lstTestUsers);
        ContEmailConfig controller = new ContEmailConfig(emailSSC);
        Controller.surveyid = survey.id;
        
        /*
         * test the removal button
         */
        
        
        controller.tempremoval = lstTestUsers[0].Name == 'delete'? lstTestUsers[0].Id : lstTestUsers[1].Id;     //some really hacky lazy stuff
        controller.removefromlist();
        System.assertEquals(1,controller.icountsize);
        
        
        /*
         * test the send email
         */
        controller.emailsending();
        SurveyResponse__c resp = [select id,name from SurveyResponse__c where Survey__c =: survey.id and Contact__c =: controller.lstCont[0].id limit 1];
        System.assert(resp != null);
    }
}