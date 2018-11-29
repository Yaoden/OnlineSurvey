@isTest
public class ExamPageControllerTest {
    
	@TestSetup static void setup(){
        
    
        List<Question__c> lstQues = new List<Question__c>();
        List<SurveyJoinQuestion__c> listJunc = new List<SurveyJoinQuestion__c>();
        
        /*
         * Creates two test contacts: one to be emailed and one to be deleted 
         */
        Contact testUser = new Contact(FirstName='test',LastName='user',email='testuser@test.com');
        insert testUser;
           

        /*
         * Creates test exam
         */ 
        
		Survey__c exam1 = new Survey__c(name='test exam 1',
			RecordTypeId=Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId(),
			Randomized__c = true,
			ShowOneQuestion__c = true,
			NumberofMinutes__c = 20,
			ShowScore__c = true,
			NumberofQuestions__c = 0
		);
		
	    Survey__c exam2 = new Survey__c(name='test exam 2',
			RecordTypeId=Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId(),
			Randomized__c = true,
			ShowOneQuestion__c = true,
			NumberofMinutes__c = 20,
			ShowScore__c = true,
			NumberofQuestions__c = 1
		);
		
        insert exam1;
        insert exam2;
        
        
        
        /*
         * Creates a Survey response object
         */
        
        SurveyResponse__c resp = new SurveyResponse__c(Survey__c = exam1.id, Contact__c = testUser.id);
        SurveyResponse__c testresp = new SurveyResponse__c(Survey__c = exam2.id, Contact__c = testUser.id);
        
        insert resp;
        insert testresp;
        
        /*
         * Create four questions true/false,radio button, open ended, and multiple choice
         */
        
        //true or false
        Question__c testQuestion = new Question__c(
    		RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId(),
    		CorrectAnswer__c='True',
    		Questionfor__c = 'Exam',
            Question_Text__c='True or false question');
        lstQues.add(testQuestion);
        
        //radio button
        testQuestion = new Question__c(
            RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId(),
            Questionfor__c = 'Exam',
            CorrectAnswer__c='B',
            Question_Text__c='Radio button question',
            Choice_A__c = 'Choice A',
            Choice_B__c = 'Choice B',
            Choice_C__c = 'Choice C',
            Choice_D__c = 'Choice D',
            Choice_E__c = 'Choice E'); 
		lstQues.add(testQuestion);
        
        
        //multiple choice
        testQuestion = new Question__c(
            RecordTypeId=Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId(),
            Questionfor__c = 'Exam',
            CorrectAnswer__c='B|C|D',
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
            listJunc.add(new SurveyJoinQuestion__c(Survey__c=exam1.id,Question__c=lstQues[i].id));
            listJunc.add(new SurveyJoinQuestion__c(Survey__c=exam2.id,Question__c=lstQues[i].id));
        }
        
        insert listJunc;
         
    }
    
    @isTest
    private static void testExam(){
    	
    	
    	Survey__c exam = [select id,name from Survey__c where name = 'test exam 1' limit 1];
    	Survey__c exam2 = [select id,name from Survey__c where name = 'test exam 2' limit 1];
    	Contact examTaker = [select id,name from Contact where FirstName='test' AND LastName='user'];
    	SurveyResponse__c examResp = [select id,name,survey__c,Contact__c from SurveyResponse__c where survey__c =: exam.id AND Contact__c =: examTaker.id];
    	SurveyResponse__c testResp = [select id,name,survey__c,Contact__c from SurveyResponse__c where survey__c =: exam2.id AND Contact__c =: examTaker.id];
       /**
    	* Used to test number of questions selected for the exam
    	*/
    	PageReference testPage = Page.ExamStartPage;
    	testPage.getParameters().put('surveyresponseid',testResp.id);
    	Test.setcurrentPage(testPage); 
    	ExamPageController testController = new ExamPageController();
    	System.assertEquals(1,testController.NumQuestions);
    	

    	
    	
    	
       /**
    	* Testing for exam where all the questions are displayed
    	*/
    	
    	PageReference startPage = Page.ExamStartPage;
    	startPage.getParameters().put('surveyresponseid',examResp.id);
    	Test.setcurrentPage(startPage); 
    	ExamPageController examController = new ExamPageController();
    	System.assertEquals(3,examController.NumQuestions);
    	examcontroller.isOneByOne = false;
    	String pageurl = examcontroller.start().getUrl();
    	System.assertEquals('/apex/exampage',pageurl);
    	examcontroller.getQuestionDynamicForm();
        
        
        
        //Tests the private method getQuestionChoices() with a true/false question and multiple choice question
         
        List<String> choices;
        Question__c multi = [select id,name,RecordType.Name,Choice_A__c,Choice_B__c,Choice_C__c,Choice_D__c,Choice_E__c from Question__c where RecordType.Name = 'Multiple Choice' limit 1];
        Question__c tf = [select id,name,RecordType.Name from Question__c where RecordType.Name = 'True/False' limit 1];
        choices = examcontroller.getQuestionChoices(tf);
        System.assert(choices.size() == 2);
        choices = examcontroller.getQuestionChoices(multi);		//to be used when testing the save() method
        System.assert(choices.size() == 5);
        
        
       /**
        * Testing for exam where questions are displayed one by one
        */
        
        
        examController = new ExamPageController();
        examcontroller.isOneByOne = true;
    	pageurl = examcontroller.start().getUrl();
    	System.assertEquals('/apex/examonebyonepage',pageurl);
        examcontroller.getQuestionOnebyOne();
        
        //testing the buttons
        System.assertEquals(true,examController.getdisabledPrev());
        System.assertEquals(false,examController.getdisabledNext());
        examController.next();
        examcontroller.getQuestionOnebyOne();
        examController.prev();
        examController.next();
        examController.next();
        examcontroller.getQuestionOnebyOne();
        
    	for(Question__c q: examcontroller.questions){
            if(q.RecordType.Name =='True/False'){
                examcontroller.responseByQuestionId.put(q.id,'True');
            }else if(q.RecordType.Name =='Multiple Choice'){
                examcontroller.selectedOptionsByQuestionId.put(q.id,new List<String>{'B|C|D'});
            }else if(q.RecordType.Name =='Radio'){
                examcontroller.responseByQuestionId.put(q.id,q.Choice_B__c);
            }
        }
        String url = examcontroller.submit().getUrl();
        SurveyResponse__c survResp = [select id,name,Survey__c,(Select Id,Name from Answers__r) from SurveyResponse__c limit 1];
        System.assertEquals(3, examcontroller.numCorrectQuestions);
        System.assertEquals('/apex/examscorepage', url);
    	
    	
    }
    
}