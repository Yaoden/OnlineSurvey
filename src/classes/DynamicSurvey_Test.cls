@isTest
public class DynamicSurvey_Test {
	
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
		
        Contact deleteUser = new Contact(FirstName='delete',LastName='me',email='deleteme@test.com');
		insert deleteUser;        

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
     * Test method that tests the DynamicSurveyForm Visualforce page and controller
	 */     
    
    @isTest
    public static void testDynamicSurvey(){
             
        //creates a new page reference that references the DynamicSurveyForm visualforce page
        PageReference pref = Page.DynamicSurveyForm;
        
        /*
         * the Id's of the survey and contact are used to populate the values in the URL
         */
        Survey__c surv = [Select Id,Name from Survey__c limit 1];
        Contact con = [Select id,name,email from Contact where FirstName='test' AND LastName='user' limit 1];
		SurveyResponse__c resp = [select id,name,Contact__c,Survey__c from SurveyResponse__c where Contact__c =: con.id AND Survey__c =: surv.id limit 1];
        pref.getParameters().put('surveyresponseid',resp.id);
        Test.setCurrentPage(pref);
        
        /*
         * Testing controller constructor
         */
        DynamicSurveyFormController controller = new DynamicSurveyFormController();
        controller.contactId = null;	//tests for when the contactId is not provided
        System.assertEquals(4, controller.NumQuestions);
        
        /*
         * Tests the method that creates the dynamic form
         */
        controller.getQuestionDynamicForm();
        
        
        /*
         * Tests the private method getQuestionChoices() with a true/false question and multiple choice question
         */
        List<String> choices;
        Question__c multi = [select id,name,RecordType.Name,Choice_A__c,Choice_B__c,Choice_C__c,Choice_D__c,Choice_E__c from Question__c where RecordType.Name = 'Multiple Choice' limit 1];
        Question__c tf = [select id,name,RecordType.Name from Question__c where RecordType.Name = 'True/False' limit 1];
        choices = controller.getQuestionChoices(tf);
        System.assert(choices.size() == 2);
        choices = controller.getQuestionChoices(multi);		//to be used when testing the save() method
        System.assert(choices.size() == 5);

        
        
        /*
         * Testing the save() method
         */
        
        //testing the save() method with a faulty email. Negative testing
        //controller.userEmail = 'trigger exception';
        controller.save();
        
        //testing the save() method with a valid email. Positive testing
        //controller.userEmail = con.Email;
        for(Question__c q: controller.questions){
            if(q.RecordType.Name =='True/False'){
                controller.responseByQuestionId.put(q.id,'true');
            }else if(q.RecordType.Name =='Multiple Choice'){
                controller.selectedOptionsByQuestionId.put(q.id,choices);
            }else if(q.RecordType.Name =='Radio'){
                controller.responseByQuestionId.put(q.id,q.Choice_C__c);
            }else if(q.RecordType.Name =='Short Answer'){
                controller.responseByQuestionId.put(q.id,'Short Answer Response');
            }
        }
        String url = controller.save().getUrl();
        SurveyResponse__c survResp = [select id,name,Survey__c,(Select Id,Name from Answers__r) from SurveyResponse__c limit 1];
        System.assertEquals(controller.NumQuestions,survResp.Answers__r.size());
        System.assertEquals('/apex/surveyComplete', url);
        
        
       /**
        * Testing for survey response page
        */
        PageReference respPage = Page.DynamicSurveyResponse;
        respPage.getParameters().put('surveyresponseid',resp.id);
        Test.setcurrentPage(respPage);
        
        DynamicSurveyResponseExtension respExtension = new DynamicSurveyResponseExtension(new ApexPages.StandardController(resp));
        
        Component.Apex.PageBlock respBlock = respExtension.getResponsePage();
        System.assertEquals(controller.questions.size()*2,respBlock.childComponents.size());
        respExtension.setupSelectedAnswers();
        
    }
}