public class contnewsurvey {
	public string strsurveyname{
		get;set;
	}
	public string strsurveyrecordtypeid{
		get;set;
	}
	public list<SelectOption> surveytypes{
		get;set;
	}
	public decimal numberofminutes{
		get;set;
	}
	public decimal numberofquestions{
		get;set;
	}
	public boolean randomized{
		get;set;
	}
	public boolean showscore{
		get;set;
	}
	public boolean showonequestion{
		get;set;
	}
	
	public boolean pageblock1{
		get;set;
	}
	public boolean pageblock2{
		get;set;
	}
	public boolean pageblock3{
		get;set;
	}
	public boolean pageblock4{
		get;set;
	}
	public boolean pageblock5{
		get;set;
	}
	public boolean pageblock6{
		get;set;
	}
	public boolean pageblock7{
		get;set;
	}
	public boolean pageblock8{
		get;set;
	}
	public boolean pageblock9{
		get;set;
	}
	
	public string stroutputid{
		get;set;
	}
	public list<question__c> questions{
		get;set;
	}
	public list<selectoption> questiontypes{
		get;set;
	}
	public string questiontypeid{
		get;set;
	}
    /*
	public list<recordtype> questionrecordtypes{
		get;set;
	}
	*/
	public string questiontext{
		get;set;
	}
	public list<selectoption> questionfortype{
		Get;set;
	}
	public string questionfortypestr{
		get;set;
	}
	Public string correctanswer{
		get;set;
	}
	public string questiona{
		get;set;
	}
	public string questionb{
		get;set;
	}
	public string questionc{
		get;set;
	}
	public string questiond{
		get;set;
	}
	public string questione{
		get;set;
	}
	public list<selectoption> existingquestions{
		get;set;
	}
	public string oldquestionid{
		get;set;
	}
	public string holdidfordelete{
		get;set;
	}
	public list<selectoption> truefalsequestion{get;set;}
	public string truefalsequestionoutput{get;set;}
	public list<string> linkedquestionids{get;set;}
	//Constructor for the page, initializes the pageblock booleans for rendering
	public contnewsurvey(ApexPages.StandardController stdcontroller) {
		//surveyRecordTypes = Schema.SObjectType.Survey__c.getRecordTypeInfosByName();
		//questionRecordTypes = Schema.SObjectType.Question__c.getRecordTypeInfosByName();
		linkedquestionids = new list<String>();
		list<Schema.RecordTypeInfo> templst = new list<Schema.RecordTypeInfo>();
		/*
		pageblock1 = true;
		pageblock2 = false;
		pageblock3 = false;
		pageblock4 = false;
		pageblock5 = false;
		pageblock6 = false;
		pageblock7 = false;
		pageblock8 = false;
		pageblock9 = false;
		*/
		questiontypes = new list<selectoption>();
		oldquestionsgetter();
		
		//sets up the options for true/false questions
		truefalsequestion = new list<selectoption>();
		truefalsequestion.add(new selectoption('True','True'));
		truefalsequestion.add(new selectoption('False','False'));

		//sets 
		questionfortype = new list<selectoption>();
		questionfortype.add(new selectoption('Survey', 'Survey'));
		questionfortype.add(new selectoption('Exam', 'Exam'));
		surveytypes = new list<SelectOption>();
		if (stroutputid != null) {
			questiontypes();
		}
		templst = Schema.SObjectType.Survey__c.getRecordTypeInfos();
		//templst = [select name, id, SobjectType from recordtype where SobjectType = 'Survey__c'];
		for (Schema.RecordTypeInfo r:templst) {
			if (r.getName() != 'Master') {
				surveytypes.add(new SelectOption(r.getRecordTypeId(), r.getName()));
			}
		}
	}

	//inserts new survey is dependant upon survey record type. ***NEEDS TO BE UPDATE***
	public void createsurvey() {
		survey__c s = new survey__c();
		s.Name = strsurveyname;
		s.recordtypeid = strsurveyrecordtypeid;
		if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId()) {
			s.NumberofMinutes__c = numberofminutes;
			s.NumberofQuestions__c = numberofquestions;
			s.Randomized__c = randomized;
			s.ShowScore__c = showscore;
			s.ShowOneQuestion__c = showonequestion;
			pageblock3 = false;
		}
		insert s;
		stroutputid = s.id;
		pageblock2 = true;

		if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId()) {


			for (Schema.RecordTypeInfo r:Schema.SObjectType.Question__c.getRecordTypeInfos()) {
				if (r.getName() != 'Short Answer' && r.getName() != 'Master') {
					questiontypes.add(new selectoption(r.getRecordTypeId(), r.getName()));
				}
			}
		} else if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId()) {
			for (Schema.RecordTypeInfo r:Schema.SObjectType.Question__c.getRecordTypeInfos()) {
				if (r.getName() != 'Master') {
					questiontypes.add(new selectoption(r.getRecordTypeId(), r.getName()));
				}
			}
		}
	}

//decides what happens after the survey record type is chosen
	public PageReference afterchosensurveytype() {
		if (strsurveyrecordtypeid == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId()) {
			return Page.ExamRecordType;
		} //else if (strsurveyrecordtypeid == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId()) {
			return Page.QuestionsPage;
			//createsurvey();
		//}

	}

	public void questiontypes() {
		Survey__c templst =
		[SELECT id, (SELECT Question__c FROM SurveyJunction__r) FROM Survey__c where id =: stroutputid];
		list<string> questionIds = new List<String>();
		for (SurveyJoinQuestion__c temp : templst.SurveyJunction__r) {
			questionIds.add(temp.Question__c);
		}
		//[select question__r.questiontext__c from surveyjunction__c where survey__c =: stroutputid]

		questions = [select Question_Text__c, id from question__C where id in: questionIds ];
	}


	//returns to the questions page
	public PageReference goBackToQuestions() {
		return Page.QuestionsPage;
	}
	//redirects to the new question page
	public PageReference makenewquestion() {
		return Page.NewQuestionsPage;
	}
	//redirects to the existing questions page
	public PageReference linkquestion() {
		//populates list of already existing questions from the SF database
		oldquestionsgetter();
		return Page.ExistingQuestionsPage;
	}
	//allows the user to select a record type for the question object
	public PageReference choosewhichquestiontypetocreate() {

		PageReference questionPage = Page.UnderConstruction;

		if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId()) {
				questionPage = Page.MultipleChoiceQuestionPage;
		}else if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId()) {
				questionPage = Page.RadioButtonQuestionPage;
		}else if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Short Answer').getRecordTypeId()) {
				questionPage = Page.ShortAnswerQuestionPage;
		}else if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId()) {
				questionPage = Page.TrueOrFalseQuestionPage;
		}else{
			//error report here
		}
		
		return questionPage;
	}
	//inserts the new question based on the question type
	public void insertnewquestion() {
		question__c q = new question__c();
		q.recordtypeid = questiontypeid;
		if (questionfortypestr == null || String.isBlank(questionfortypestr)) {
			questionfortypestr = 'Survey';
		}
		if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId()) {
			q.questionfor__c = 'Exam';
		}
		if (strsurveyrecordtypeid == Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId()) {
			q.questionfor__c = 'Survey';
		}
		q.question_text__c = questiontext;
		questiontext = '';
		if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId() || questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId()) {
			//multiple choice && radio
			q.choice_a__c = questiona;
			q.choice_b__c = questionb;
			q.choice_c__c = questionc;
			q.choice_d__c = questiond;
			q.choice_e__c = questione;
			q.correctanswer__c = correctanswer;
			questiona = '';
			questionb = '';
			questionc = '';
			questiond = '';
			questione = '';
			correctanswer = '';

		}
		if (questiontypeid == Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId()) {
			//true false
			q.correctanswer__c = truefalsequestionoutput;
		}
		insert q;
		surveyjoinquestion__c sjq = new surveyjoinquestion__c();
		sjq.question__c = q.id;
		sjq.survey__c = stroutputid;
		insert sjq;
		linkedquestionids.add(q.id);

		pageblock2 = true;
		pageblock3 = false;
		pageblock4 = false;
		pageblock5 = false;
		pageblock6 = false;
		pageblock7 = false;
		pageblock8 = false;
		pageblock9 = false;
		questiontypes();

	}
	//links to the an old question that was queried
	public void linktooldquestion() {
		surveyjoinquestion__c sjq = new surveyjoinquestion__c();
		sjq.question__c = oldquestionid;
		sjq.survey__c = stroutputid;
		insert sjq;
		linkedquestionids.add(oldquestionid);


		questiontypes();
		pageblock4 = false;
		pageblock5 = false;
		pageblock9 = false;
		pageblock2 = true;


	}
	//gets all the old questions, called in multiple places
	public void oldquestionsgetter() {
		existingquestions = new list<selectoption>();
		existingquestions.clear();
		if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId()) {
			//exam record type id
			list<question__c> templst =
			[select question_text__c , id, questionfor__c from question__c where questionfor__c = 'Exam' and id !=: linkedquestionids];
			for (question__c qc:templst) {

				existingquestions.add(new SelectOption(qc.Id, qc.question_text__c));
			}
		}
		if (strsurveyrecordtypeid ==
				Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId()) {
			//survey record type id
			list<question__c> templst =
			[select question_text__c , id, questionfor__c from question__c where questionfor__c = 'Survey' and id !=: linkedquestionids];
			for (question__c qc:templst) {

				existingquestions.add(new SelectOption(qc.Id, qc.question_text__c));
			}
		}
	}
//removes question from the survey
	public void removequestion() {
		//surveyjoinquestion__c sjq = [select id, question__c, survey__c from surveyjoinquestion__c where question__c = 'holdidfordelete' AND survey__c =: stroutputid];
		system.debug(holdidfordelete);
		list<surveyjoinquestion__c> sjq =
		[select id, question__c, survey__c from surveyjoinquestion__c where question__c =: holdidfordelete AND survey__c =: stroutputid];
		for (surveyjoinquestion__c c:sjq) {
			delete c;
		}
		questiontypes();
	}
	//removes question from the survey and from the database( removes junction object and question object)
	public void removetotalquestion() {
		question__c qc = new question__c();
		qc.id = holdidfordelete;
		delete qc;
		removequestion();
	}

}