/**
* @description DynamicSurveyFormController creates a dynamic form from a surveyId
*/
public with sharing class DynamicSurveyFormController {
    private static final String TRUE_FALSE_TYPE = 'True/False';
    private static final String MULTIPLE_CHOICE_TYPE = 'Multiple Choice';
    private static final String RADIO_TYPE = 'Radio';
    private static final String TEXT_TYPE = 'Short Answer';
    private static final String MULTIPLE_CHOICE_SEPARATOR = '|';

    public List<Question__c> questions{get;set;}
    public Id surveyId{get;set;} // used to get survey
    public Id contactId{get;set;} // used to get contact
    public Id surveyResponseId {get;set;} //used to get survey response id
    public SurveyResponse__c surveyResponse {get;set;}
    public Survey__c survey{get;set;}
    public boolean isFilled{get;set;}
    public boolean notFound{get;set;}
    public Map<String,String> responseByQuestionId{get;set;} // stores answers to questions. short answer, radio, true/false
    public Map<String,List<String>> selectedOptionsByQuestionId{get;set;} // stores answers to multiple choice questions
    public Map<String,List<SelectOption>> availableOptionsByQuestionId{get;set;} // used to fill available options on the form
    public Integer NumQuestions{get;set;}
    private String surveyType{get;set;}
    /**
    * @description Constructor gets survey and contact ids from parameters and initializes variables
    */
    public DynamicSurveyFormController() {
        questions = new List<Question__c>();
        responseByQuestionId = new Map<String,String>();
        selectedOptionsByQuestionId = new Map<String,List<String>>();
        availableOptionsByQuestionId = new Map<String,List<SelectOption>>();
		NumQuestions = 0;
        surveyResponseId = apexpages.currentpage().getparameters().get('surveyresponseid');

        try{
            surveyResponse = [select id,name,Contact__c,Survey__c,Survey_Status__c from SurveyResponse__c where id =: surveyResponseId];

            if(surveyResponse.Survey_Status__c == 'Filled Out'){
                isFilled = true;
            }else{
                isFilled = false;
            }

            surveyId = surveyResponse.Survey__c;
            contactId = surveyResponse.Contact__c;

            survey = [select Id, Name, RecordType.Name,NumberofQuestions__c,NumberofMinutes__c,Randomized__c,ShowOneQuestion__c,ShowScore__c  from survey__c where id =: surveyId];
            surveyType = survey.RecordType.Name;
            
        }catch(QueryException e){
            notFound = true;
            return;
        }
        List<SurveyJoinQuestion__c> joins = [SELECT Id, Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name FROM SurveyJoinQuestion__c WHERE Survey__r.Id = :surveyId];

        for(SurveyJoinQuestion__c j : joins){
            questions.add(j.Question__r);
        }
        NumQuestions = questions.size();
		
		setupAnswers();

        if(questions.size() < 1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Questions'));
        }
    }

    /**
    * @description Adds existing answers to the answer maps for display in dynamic form
    */
    private void setupAnswers(){

        List<SurveyJoinQuestion__c> joins = [
                SELECT Id, Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name
                FROM SurveyJoinQuestion__c
                WHERE Survey__r.Id = :surveyResponse.Survey__c
        ];

        List<Answers__c> existingAnswers = [
                SELECT Id, Question__c, TextfieldAnswer__c
                FROM Answers__c
                WHERE SurveyResponse__c = :surveyResponse.Id
        ];
        Map<Id, Answers__c> existingAnswersByQuestionId = new Map<Id, Answers__c>();
        for(Answers__c answer : existingAnswers){
            existingAnswersByQuestionId.put(answer.Question__c, answer);
        }

        for(Question__c q : questions) {
            Answers__c answer;
            if (existingAnswersByQuestionId.containsKey(q.Id)) {
                answer = existingAnswersByQuestionId.get(q.Id);

                if (q.RecordType.Name == MULTIPLE_CHOICE_TYPE) {
                    if(answer.TextfieldAnswer__c != null) {
                        List<String> selectedChoices = answer.TextfieldAnswer__c.split('\\|');
                        selectedOptionsByQuestionId.put(q.Id, selectedChoices);
                    }
                } else {
                    responseByQuestionId.put(q.Id, answer.TextfieldAnswer__c);
                }
            }
        }
    }

    /**
    * @description Creates and returns a dynamic form as a pageBlock component
    * @return a pageBlock component with labels and inputs
    */
    public Component.Apex.PageBlock getQuestionDynamicForm() {
        Component.Apex.PageBlock dynPageBlock = new Component.Apex.PageBlock();
        
       /**
        * Initial error checking:
        * 1. Checks if survey has questions
        * 2. Checks if survey is already filled out
        */
        if(questions.size() < 1 || surveyType == 'Exam'){
            return dynPageBlock; // don't display anything if there are no questions
        }else if(isFilled){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Survey has already been filled out'));
            return dynPageBlock;
        }

		setUpSurvey(dynPageBlock);

        return dynPageBlock;
    }

   /*
    * Creates the survey where all the questions are on a single page
    */
    private void setUpSurvey(Component.Apex.PageBlock dynPageBlock){
        // creates labels and inputs for each question
        for (Question__c q : questions) {
            String questionType = q.RecordType.Name;

            Component.Apex.OutputLabel theQuestionLabel = new Component.Apex.OutputLabel();
            theQuestionLabel.value = q.Question_Text__c;
            theQuestionLabel.styleClass = 'questions';
            dynPageBlock.childComponents.add(theQuestionLabel);

            if(questionType != MULTIPLE_CHOICE_TYPE && !responseByQuestionId.containsKey(q.Id) || responseByQuestionId.get(q.Id) == null) {
                responseByQuestionId.put(q.Id, ''); // must have value or will get error
            }
            if(questionType == MULTIPLE_CHOICE_TYPE && !selectedOptionsByQuestionId.containsKey(q.Id) || selectedOptionsByQuestionId.get(q.Id) == null){
                selectedOptionsByQuestionId.put(q.Id, new List<String>()); // must be initialized or will get error
            }

            if (questionType == TEXT_TYPE) {
                Component.Apex.InputTextArea theInput = new Component.Apex.InputTextArea();
                theInput.expressions.value = '{!responseByQuestionId["'+q.Id+'"]}';
                dynPageBlock.childComponents.add(theInput);
                theInput.styleClass = 'choices';

            } else if (questionType == TRUE_FALSE_TYPE || questionType == RADIO_TYPE) {
                Component.Apex.SelectRadio theInput = new Component.Apex.SelectRadio();
                theInput.expressions.value = '{!responseByQuestionId["'+q.Id+'"]}';
                theInput.styleClass = 'choices';

                List<String> availableOptions = getQuestionChoices(q);
                List<SelectOption> selectOptions = new List<SelectOption>();
                for(String choice : availableOptions){
                    selectOptions.add(new SelectOption(choice, choice));
                }
                availableOptionsByQuestionId.put(q.Id, selectOptions);
                Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
                selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["'+q.Id+'"]}';
                theInput.childComponents.add(selectOptionsComponent);
                dynPageBlock.childComponents.add(theInput);

            } else if (questionType == MULTIPLE_CHOICE_TYPE) {
                Component.Apex.SelectCheckboxes theInput = new Component.Apex.SelectCheckboxes();
                theInput.expressions.value = '{!selectedOptionsByQuestionId["'+q.Id+'"]}';
                theInput.styleClass = 'choices';

                List<String> availableOptions = getQuestionChoices(q);

                List<SelectOption> selectOptions = new List<SelectOption>();

                for(String choice : availableOptions){
                    selectOptions.add(new SelectOption(choice, choice));
                }
                availableOptionsByQuestionId.put(q.Id, selectOptions);

                Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
                selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["'+q.Id+'"]}';
                theInput.childComponents.add(selectOptionsComponent);

                dynPageBlock.childComponents.add(theInput);
            }

        }
    }
    
    /**
    * @description Utility method that returns available choices for a question
    * @param question the Question__c record to get choices for
    * @return a list of choices as strings
    */
    @TestVisible
    private List<String> getQuestionChoices(Question__c question){
        List<String> choices = new List<String>();

        if(question.RecordType.Name == TRUE_FALSE_TYPE){
            return new List<String>{'True', 'False'};
        }

        if(question.Choice_A__c != null)
            choices.add(question.Choice_A__c);
        if(question.Choice_B__c != null)
            choices.add(question.Choice_B__c);
        if(question.Choice_C__c != null)
            choices.add(question.Choice_C__c);
        if(question.Choice_D__c != null)
            choices.add(question.Choice_D__c);
        if(question.Choice_E__c != null)
            choices.add(question.Choice_E__c);

        return choices;
    }

    /**
    * @description Saves the user's reponse as a SurveyResponse__c and Answers__c records
    * @return the PageReference with redirect to new page or null if errors are encountered
    */
    public PageReference save(){
        if(questions.size() < 1 || isFilled || surveyType == 'Exam') return null;

        // Update survey Response and add Answers with relation to question
        SurveyResponse__c surveyResponse = [
                SELECT Id, Survey__c, Contact__c
                FROM SurveyResponse__c
                WHERE Id = :surveyResponseId
                LIMIT 1
        ];

        Savepoint sp = Database.setSavepoint();

        // update existing answers instead of always creating new answers
        List<Answers__c> existingAnswers = [
                SELECT Id, Question__c
                FROM Answers__c
                WHERE SurveyResponse__c = :surveyResponseId
        ];
        Map<Id, Answers__c> existingAnswersByQuestionId = new Map<Id, Answers__c>();
        for(Answers__c answer : existingAnswers){
            existingAnswersByQuestionId.put(answer.Question__c, answer);
        }

        List<Answers__c> answers = new List<Answers__c>();
        Boolean hasUnansweredQuestion = false;
        for(Question__c q : questions){
            Answers__c answer;
            if(existingAnswersByQuestionId.containsKey(q.Id)){
                answer = existingAnswersByQuestionId.get(q.Id);
            }else {
                answer = new Answers__c(
                        SurveyResponse__c = surveyResponse.Id,
                        Question__c = q.Id
                );
            }
            if(q.RecordType.Name == MULTIPLE_CHOICE_TYPE) {
                // Save multiple choice answers as a single string
                answer.TextfieldAnswer__c =
                        String.join(selectedOptionsByQuestionId.get(q.Id), MULTIPLE_CHOICE_SEPARATOR);
            }else {
                answer.TextfieldAnswer__c = responseByQuestionId.get(q.Id);
            }
            if(!String.isBlank(answer.TextfieldAnswer__c))
                answers.add(answer);
            else{
                // Update existing answers with blank value, but don't count them as answered
                // TODO: delete existing answers instead of setting answer to blank?
                if(existingAnswersByQuestionId.containsKey(q.Id)){
                    answers.add(answer);
                }
                hasUnansweredQuestion = true;
            }
        }
        try {
            upsert answers;

        }catch(Exception e){
            System.debug('Error saving answers: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while attempting to save answers'));
            return null;
        }

        try{
            // Surveys are 'Not Finished' if they have unanswered questions or 'Filled Out' if all questions are answered
            if(!hasUnansweredQuestion){
                surveyResponse.Survey_Status__c = 'Filled Out';     //minor but could use Dynamic Apex
            }else{
                surveyResponse.Survey_Status__c = 'Not Finished';
            }
            update surveyResponse;
        }catch(Exception e){
            System.debug('Error saving SurveyResponse: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while attempting to save response'));
            return null;
        }

        PageReference nextPage = new PageReference('/apex/surveyComplete');
        nextPage.setRedirect(true);
        return nextPage;
    }
}