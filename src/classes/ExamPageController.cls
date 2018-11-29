public class ExamPageController {

	private static final String TRUE_FALSE_TYPE = 'True/False';
	private static final String MULTIPLE_CHOICE_TYPE = 'Multiple Choice';
	private static final String RADIO_TYPE = 'Radio';
	private static final String MULTIPLE_CHOICE_SEPARATOR = '|';

	public List<Question__c> questions{get;set;}
	public Id surveyId{get;set; } // used to get survey
	public Id contactId{get;set; } // used to get contact
	public Id surveyResponseId {get;set; } //used to get survey response id
	public SurveyResponse__c surveyResponse {get;set; }
	public Survey__c survey{get;set; }
	public Map<String, String> responseByQuestionId{get;set; } // stores answers to questions. short answer, radio, true/false
	public Map<String, List<String>> selectedOptionsByQuestionId{get;set; } // stores answers to multiple choice questions
	public Map<String, List<SelectOption>> availableOptionsByQuestionId{get;set; } // used to fill available options on the form
	public Integer NumQuestions{get{return questions.size(); }set; }
	public Integer numCorrectQuestions{get;set; }
	private String surveyType{get;set; }
	public boolean isFilled{get;set; }
	public boolean notFound{get;set; }
	public boolean isOneByOne{get;set; }
	public integer currentQues{get;set; }
	public boolean showScore{get;set; }
	public DateTime endTime{get;set; }
	public Map<String, Boolean> shouldReviewByQuestionId{get;set;}
	public Id currentQuestionId{get;set;}

	public ExamPageController() {

		notFound = false;
		currentQues = 1;
		questions = new List<Question__c>();
		responseByQuestionId = new Map<String, String>();
		selectedOptionsByQuestionId = new Map<String, List<String>>();
		availableOptionsByQuestionId = new Map<String, List<SelectOption>>();
		shouldReviewByQuestionId = new Map<String, Boolean>();
		List<SurveyJoinQuestion__c> joins;

		/**
		 *	Query for the surveyresponse corresponding to the contact, the survey, and the questions
		 */
		try {
			surveyResponseId = ApexPages.currentPage().getParameters().get('surveyresponseid');
			surveyResponse = [
					SELECT id,name,Contact__c,Survey__c,Survey_Status__c,StartTime__c,ExamScore__c
					FROM SurveyResponse__c
					WHERE id =: surveyResponseId
			];

			if (surveyResponse.Survey_Status__c == 'Filled Out') {
				isFilled = true;
			} else {
				isFilled = false;
			}

			surveyId = surveyResponse.Survey__c;
			contactId = surveyResponse.Contact__c;

			survey = [
					SELECT Id, Name, RecordType.Name,NumberofQuestions__c,NumberofMinutes__c,Randomized__c,ShowOneQuestion__c,ShowScore__c
					FROM survey__c
					WHERE id =: surveyId
			];
			joins = [
					SELECT Id, Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name, Question__r.CorrectAnswer__c
					FROM SurveyJoinQuestion__c
					WHERE Survey__r.Id = :surveyId
			];
			isOneByOne = survey.ShowOneQuestion__c;
			surveyType = survey.RecordType.Name;
			showScore = survey.ShowScore__c;

		} catch (QueryException e) {
			notFound = true;
			return;
		} catch (Exception a) {
			notFound = true;
			return;
		}

		for (SurveyJoinQuestion__c j : joins) {
			Question__c q = j.Question__r;
			questions.add(q);

		}

		if (survey.Randomized__c) {
			integer currentIndex = questions.size();
			Question__c Question;
			integer randomIndex;
			// While there remain elements to shuffle...
			while (0 != currentIndex) {
				// Pick a remaining element...
				randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
				currentIndex -= 1;
				// And swap it with the current element.
				Question = questions[currentIndex];
				questions[currentIndex] = questions[randomIndex];
				questions[randomIndex] = Question;
			}
		}

		//Randomly remove questions from the list
		if (survey.NumberofQuestions__c > 0) {
			integer totalQues = Integer.valueOf(survey.NumberofQuestions__c);
			integer currentIndex = questions.size();
			Question__c Question;
			integer randomIndex;
			// While there remain elements to shuffle...
			while (0 != currentIndex && questions.size() > totalQues) {
				// Pick a remaining element...
				randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
				currentIndex -= 1;
				questions.remove(randomIndex);
			}
		}

		for (Question__c q:questions) {
			String questionType = q.RecordType.Name;
			if( !shouldReviewByQuestionId.containsKey(q.Id) || shouldReviewByQuestionId.get(q.Id) == null){
				shouldReviewByQuestionId.put(q.Id, False);
			}
			if (questionType != MULTIPLE_CHOICE_TYPE && !responseByQuestionId.containsKey(q.Id) ||
							responseByQuestionId.get(q.Id) == null) {
				responseByQuestionId.put(q.Id, ''); // must have value or will get error
			}
			if (questionType == MULTIPLE_CHOICE_TYPE && !selectedOptionsByQuestionId.containsKey(q.Id) ||
							selectedOptionsByQuestionId.get(q.Id) == null) {
				selectedOptionsByQuestionId.put(q.Id, new List<String>()); // must be initialized or will get error
			}

			List<String> availableOptions = getQuestionChoices(q);
			List<SelectOption> selectOptions = new List<SelectOption>();
			for (String choice : availableOptions) {
				selectOptions.add(new SelectOption(choice, choice));
			}
			availableOptionsByQuestionId.put(q.Id, selectOptions);
		}

	}

	/**
	 * The questions on the exam are displayed on one page
	 */

	public Component.Apex.OutputPanel getQuestionDynamicForm() {
        refreshStatus();
		// creates labels and inputs for each question
		Component.Apex.OutputPanel dynPageBlock = new Component.Apex.OutputPanel();
		if (questions.size() < 1) {
			return dynPageBlock; // don't display anything if there are no questions
		} else if (isFilled) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exam has already been taken'));
			return dynPageBlock;
		}
		for (Question__c q : questions) {
			String questionType = q.RecordType.Name;

			Component.Apex.OutputLabel theQuestionLabel = new Component.Apex.OutputLabel();
			theQuestionLabel.value = q.Question_Text__c;
			theQuestionLabel.styleClass = 'questions';
			dynPageBlock.childComponents.add(theQuestionLabel);


			if (questionType == TRUE_FALSE_TYPE || questionType == RADIO_TYPE) {
				Component.Apex.SelectRadio theInput = new Component.Apex.SelectRadio();
				theInput.expressions.value = '{!responseByQuestionId["' + q.Id + '"]}';
				theInput.styleClass = 'choices';

				Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
				selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["' + q.Id + '"]}';
				theInput.childComponents.add(selectOptionsComponent);
				dynPageBlock.childComponents.add(theInput);

			} else if (questionType == MULTIPLE_CHOICE_TYPE) {
				Component.Apex.SelectCheckboxes theInput = new Component.Apex.SelectCheckboxes();
				theInput.expressions.value = '{!selectedOptionsByQuestionId["' + q.Id + '"]}';
				theInput.styleClass = 'choices';


				Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
				selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["' + q.Id + '"]}';
				theInput.childComponents.add(selectOptionsComponent);

				dynPageBlock.childComponents.add(theInput);
			}
		}
		return dynPageBlock;
	}

	/**
	 *	If the OneByOne__c field on exam is check. The exam will be displayed one question at a time.
	 */

	public Component.Apex.OutputPanel getQuestionOneByOne() {
        refreshStatus();
		// creates labels and inputs for each question
		Component.Apex.OutputPanel dynPageBlock = new Component.Apex.OutputPanel();

		if (questions.size() < 1) {
			return dynPageBlock; // don't display anything if there are no questions
		} else if (isFilled) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exam has already been taken'));
			return dynPageBlock;
		}

		Question__c q = questions.get(currentQues - 1);
		String questionType = q.RecordType.Name;
		currentQuestionId = q.Id;

		Component.Apex.OutputLabel theQuestionLabel = new Component.Apex.OutputLabel();
		theQuestionLabel.value = q.Question_Text__c;
		theQuestionLabel.styleClass = 'questions';
		dynPageBlock.childComponents.add(theQuestionLabel);

		if (questionType == TRUE_FALSE_TYPE || questionType == RADIO_TYPE) {

			if (responseByQuestionId.get(q.id) == null) {
				responseByQuestionId.put(q.Id, ''); // must have value or will get error
			}

			Component.Apex.SelectRadio theInput = new Component.Apex.SelectRadio();
			theInput.expressions.value = '{!responseByQuestionId["' + q.Id + '"]}';
			theInput.styleClass = 'choices';

			Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
			selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["' + q.Id + '"]}';
			theInput.childComponents.add(selectOptionsComponent);
			dynPageBlock.childComponents.add(theInput);

		} else if (questionType == MULTIPLE_CHOICE_TYPE) {

			if (selectedOptionsByQuestionId.get(q.id) == null) {
				selectedOptionsByQuestionId.put(q.Id, new List<String>()); // must have value or will get error
			}

			Component.Apex.SelectCheckboxes theInput = new Component.Apex.SelectCheckboxes();
			theInput.expressions.value = '{!selectedOptionsByQuestionId["' + q.Id + '"]}';
			theInput.styleClass = 'choices';


			Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
			selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["' + q.Id + '"]}';
			theInput.childComponents.add(selectOptionsComponent);

			dynPageBlock.childComponents.add(theInput);
		}
		return dynPageBlock;
	}


	public boolean getDisabledNext() {
		return !(currentQues < questions.size());
	}

	public boolean getDisabledPrev() {
		return !(currentQues > 1);
	}

	public void next() {
		currentQues++;
	}

	public void prev() {
		currentQues--;
	}

	public PageReference start() {
		if(survey.NumberofMinutes__c != null && survey.NumberofMinutes__c > 0 ) {
			refreshStatus();
            if (surveyResponse.StartTime__c == null) {
				try {
					surveyResponse.StartTime__c = System.Now();
					update surveyResponse;
				} catch (DMLException e) {
					// TODO: handle exception
					return null;
				}
			}
			endTime = surveyResponse.StartTime__c.addMinutes((Integer)survey.NumberofMinutes__c);
			// Add extra time for submit. Go to results if endtime passed
			if (endTime < System.Now().addSeconds(-10))
				return Page.ExamScorePage;
		}
		if (isOneByOne) {
			return Page.ExamOneByOnePage;
		}
		return Page.ExamPage;
	}

	public PageReference submit() {
		refreshStatus();
        numCorrectQuestions = 0;
		if (isFilled) {
			return Page.ExamScorePage;
		}

		Savepoint sp = Database.setSavepoint();

		List<Answers__c> answers = new List<Answers__c>();
		for (Question__c q : questions) {
			Answers__c answer = new Answers__c(
					SurveyResponse__c = surveyResponse.Id,
					Question__c = q.Id
			);

			if (q.RecordType.Name == MULTIPLE_CHOICE_TYPE) {
				// Save multiple choice answers as a single string
				answer.TextfieldAnswer__c =
						String.join(selectedOptionsByQuestionId.get(q.Id), MULTIPLE_CHOICE_SEPARATOR);
			} else {
				answer.TextfieldAnswer__c = responseByQuestionId.get(q.Id);
			}
			if (!String.isBlank(answer.TextfieldAnswer__c))
				answers.add(answer);
		}
		try {
			insert answers;
		} catch (Exception e) {
			System.debug('Error saving answers: ' + e.getMessage());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
					'An error occurred while attempting to save answers'));
			return null;
		}

		try {
			// Exams are always 'Filled Out' when submitted
			surveyResponse.Survey_Status__c = 'Filled Out';

			update surveyResponse;
            isFilled = true;
		} catch (Exception e) {
			System.debug('Error saving Exam: ' + e.getMessage());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
					'An error occurred while attempting to save response'));
			return null;
		}

		if (showScore) {
			surveyResponse = [
					SELECT id,name,Contact__c,Survey__c,Survey_Status__c,StartTime__c,ExamScore__c
					FROM SurveyResponse__c
					WHERE id =: surveyResponseId
			];
			numCorrectQuestions = Integer.valueOf(surveyResponse.ExamScore__c);
		}

		return Page.ExamScorePage;
	}

	/**
	* @description calculates the score and sets numCorrectQuestions
	* @param answers the list of Answers__c to check for correctness
	* 
	* deprecated. Replaced with formula field on survey response to automatically calculate score for us.
	
	private void calculateScore(List<Answers__c> answers){
		// for each answer, if text matches question correct answer text, add to score
		Integer numCorrect = 0;
		Map<Id, Question__c> questionsById = new Map<Id, Question__c>(questions);
		for (Answers__c a : answers) {
			if (a.TextfieldAnswer__c.equals(questionsById.get(a.Question__c).CorrectAnswer__c)) {
				numCorrect++;
			}
		}
		numCorrectQuestions = numCorrect;
	}
	*/
	/**
	 * @description Utility method that returns available choices for a question
	 * @param question the Question__c record to get choices for
	 * @return a list of choices as strings
	 */
	@TestVisible
	private List<String> getQuestionChoices(Question__c question) {
		List<String> choices = new List<String>();

		if (question.RecordType.Name == TRUE_FALSE_TYPE) {
			return new List<String>{'True', 'False'};
		}

		if (question.Choice_A__c != null)
			choices.add(question.Choice_A__c);
		if (question.Choice_B__c != null)
			choices.add(question.Choice_B__c);
		if (question.Choice_C__c != null)
			choices.add(question.Choice_C__c);
		if (question.Choice_D__c != null)
			choices.add(question.Choice_D__c);
		if (question.Choice_E__c != null)
			choices.add(question.Choice_E__c);

		return choices;
	}

	public String getTargetTime() {
		if(endTime != null)
			return endTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
		return '';
	}
    
    private void refreshStatus(){
		// Requery surveyresponse to update status and prevent resubmitting
        surveyResponse = [
			SELECT id,name,Contact__c,Survey__c,Survey_Status__c,StartTime__c,ExamScore__c
			FROM SurveyResponse__c
			WHERE id =: surveyResponseId
		];
        isFilled = surveyResponse.Survey_Status__c == 'Filled Out';        
    }
}