@isTest
public class ControllerSurveySummaryTest {
	/*
	@isTest
	public static void testSuveySummaryController(){
		PageReference pref = Page.SurveyResultsSummarized;
		Test.setCurrentPage(pref);
		ControllerSurveySummary controller = new ControllerSurveySummary(new ApexPages.StandardController(new Survey__c()));

		System.assertEquals(3, controller.getResults().size());
		System.assertEquals(2, controller.getlstsurveyoption().size());
		System.assertEquals(False, controller.shouldHideSelect);
		System.assertNotEquals(null, controller.getJSONResults());
	}
	*/
	@TestSetup
	static void setup(){

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

		SurveyResponse__c resp2 = new SurveyResponse__c(Survey__c = surv.id, Contact__c = deleteUser.id);
		insert resp2;

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

		/*
		 * Create Answers
		 */
		List<Answers__c> answers = new List<Answers__c>();
		for(Question__c q : lstQues){
			Answers__c a1 = new Answers__c(
				Question__c = q.Id,
					SurveyResponse__c = resp.Id
			);

			Answers__c a2 = new Answers__c(
				Question__c = q.Id,
					SurveyResponse__c = resp2.Id
			);
			if(q.Question_Text__c.equals('Radio button question')) {
				a1.TextfieldAnswer__c = 'Choice A';
				a2.TextfieldAnswer__c = 'Choice B';
			}else if(q.Question_Text__c.equals('True or false question')){
				a1.TextfieldAnswer__c = 'True';
				a2.TextfieldAnswer__c = 'False';
			}else if(q.Question_Text__c.equals('Multiple Choice question')){
				a1.TextfieldAnswer__c = 'Choice A|Choice C';
				a2.TextfieldAnswer__c = 'Choice A|Choice B';
			}
			answers.add(a1);
			answers.add(a2);
		}
		insert answers;
	}
	@isTest
	public static void testSuveySummaryControllerWithParmeter(){

		Survey__c survey = [Select Id,Name from Survey__c limit 1];

		PageReference pref = Page.SurveyResultsSummarized;
		test.setCurrentPage(pref);
		ControllerSurveySummary controller = new ControllerSurveySummary(new ApexPages.StandardController(survey));

		System.assertEquals(3, controller.getResults().size());
		System.assertNotEquals(null, controller.getJSONResults());
	}


}