public with sharing class DynamicSurveyResponseExtension {
    
    private static final String TRUE_FALSE_TYPE = 'True/False';
    private static final String MULTIPLE_CHOICE_TYPE = 'Multiple Choice';
    private static final String RADIO_TYPE = 'Radio';
    private static final String TEXT_TYPE = 'Short Answer';
    
    
    public SurveyResponse__c resp{get;set;}
    public integer numQuestions{get;set;}
    public integer examScore{get;set;}
    public String sname{get;set;}
    public Survey__c surv{get;set;}
    public Map<Question__c,Answers__c> mapResp {get;set;}
    List<SurveyJoinQuestion__c> joins {get;set;}
    public boolean isFilled{get;set;}
    public boolean isExam{get;set;}
    public Map<String,String> responseByQuestionId{get;set;} // stores answers to questions. short answer, radio, true/false
    public Map<String,List<String>> selectedOptionsByQuestionId{get;set;} // stores answers to multiple choice questions
    public Map<String,List<SelectOption>> availableOptionsByQuestionId{get;set;} // used to fill available options on the form
    public Map<String,String> answerMap{get;set;}
    public List<Question__c> questions{get;set;}
    
    
    public DynamicSurveyResponseExtension(ApexPages.StandardController stdController){
        
        Id respId = (Id)stdController.getRecord().id;
        resp = [select id,name,Survey__c,Survey_Status__c,ExamScore__c,ContactName__c,(select id,name,Question__c,TextfieldAnswer__c from Answers__r) from SurveyResponse__c where id =: respId limit 1];
        surv = [select id,name,RecordType.Name,NumberofQuestions__c from Survey__c where id =: resp.Survey__c];
        sname = surv.name;
        mapResp = new Map<Question__c,Answers__c>();  
        //joins = [SELECT Id, Question__r.Id,Question__r.CorrectAnswer__c,Question__r.Questionfor__c,Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name FROM SurveyJoinQuestion__c WHERE Survey__r.Id = :resp.Survey__c];
        
        isFilled = false;
        isExam = false;
        responseByQuestionId = new Map<String,String>();
        selectedOptionsByQuestionId = new Map<String,List<String>>();
        availableOptionsByQuestionId = new Map<String,List<SelectOption>>();
        answerMap = new Map<String,String>();
        questions = new List<Question__c>();
        
        if(resp.Survey_Status__c =='Filled Out'|| resp.Answers__r.size() > 0){
        	if(surv.RecordType.Name == 'Exam' && surv.NumberofQuestions__c > 0){
        		setupSelectedAnswers();
        	}else{
	            setupAnswers();
        	}
        	isFilled = true;
        }
        
        if(surv.RecordType.Name == 'Exam'){
        	examScore = Integer.valueOf(resp.ExamScore__c);
        	isExam = true;
        }
        
        numQuestions = questions.size();
        
    }
   @TestVisible
    private void setupSelectedAnswers(){
    	
        List<Answers__c> existingAnswers = [
                SELECT Id, Question__c, TextfieldAnswer__c,Question__r.Id,Question__r.CorrectAnswer__c,Question__r.Questionfor__c,Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name
                FROM Answers__c
                WHERE SurveyResponse__c = :resp.Id
        ];
        
        //List<Question__c> questions = new List<Question__c>();
        for(Answers__c j : existingAnswers){
            questions.add(j.Question__r);
        }
        
        Map<Id, Answers__c> existingAnswersByQuestionId = new Map<Id, Answers__c>();
        for(Answers__c answer : existingAnswers){
            existingAnswersByQuestionId.put(answer.Question__c, answer);
        }

        for(Question__c q : questions) {
            Answers__c answer;
            if (existingAnswersByQuestionId.containsKey(q.Id)) {
                answer = existingAnswersByQuestionId.get(q.Id);
            
                if (q.RecordType.Name == MULTIPLE_CHOICE_TYPE) {
                    //List<String> selectedChoices = answer.MultipleChoiceOutput__c.split(',');
                    List<String> selectedChoices = answer.TextfieldAnswer__c.split('\\|');
                    selectedOptionsByQuestionId.put(q.Id, selectedChoices);
                } else {
                    if(answer.TextfieldAnswer__c != null)
                        responseByQuestionId.put(q.Id, answer.TextfieldAnswer__c);
                }
            }
        }
	
    }
    
    
    private void setupAnswers(){
        SurveyResponse__c surveyResponse = resp;
        
        List<SurveyJoinQuestion__c> joins = [
            SELECT Id, Question__r.RecordTypeId, Question__r.Choice_A__c, Question__r.Choice_B__c, Question__r.Choice_C__c, Question__r.Choice_D__c, Question__r.Choice_E__c, Question__r.Question_Text__c, Question__r.RecordType.Name, Question__r.Questionfor__c, Question__r.CorrectAnswer__c
            FROM SurveyJoinQuestion__c
            WHERE Survey__r.Id = :surveyResponse.Survey__c
        ];
        //List<Question__c> questions = new List<Question__c>();
        for(SurveyJoinQuestion__c j : joins){
            questions.add(j.Question__r);
        }

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
                    //List<String> selectedChoices = answer.MultipleChoiceOutput__c.split(',');
                    List<String> selectedChoices = answer.TextfieldAnswer__c.split('\\|');
                    selectedOptionsByQuestionId.put(q.Id, selectedChoices);
                } else {
                    if(answer.TextfieldAnswer__c != null)
                        responseByQuestionId.put(q.Id, answer.TextfieldAnswer__c);
                }
            }
        }
    }

    public Component.Apex.PageBlock getResponsePage(){
   
        Component.Apex.PageBlock dynPageBlock = new Component.Apex.PageBlock();
        integer counter = 1;
        // creates labels and inputs for each question
        for (Question__c q : questions) {
            //Question__c q = a.Question__r;
            String questionType = q.RecordType.Name;

            Component.Apex.OutputLabel theQuestionLabel = new Component.Apex.OutputLabel();
            theQuestionLabel.value = String.valueof(counter)+'. '+ q.Question_Text__c;
            theQuestionLabel.styleClass = 'questions';
            dynPageBlock.childComponents.add(theQuestionLabel);
            
            /**
             * Used for when the user did not fill out the survey
             */
            if(true || !isFilled){
                if(/*questionType != MULTIPLE_CHOICE_TYPE && */!responseByQuestionId.containsKey(q.Id) || responseByQuestionId.get(q.Id) == null) {
                    responseByQuestionId.put(q.Id, ''); // must have value or will get error
                }
                if(questionType == MULTIPLE_CHOICE_TYPE && !selectedOptionsByQuestionId.containsKey(q.Id)){
                    selectedOptionsByQuestionId.put(q.Id, new List<String>()); // must be initialized or will get error
                }
            }
            if (questionType == TEXT_TYPE) {
                Component.Apex.InputTextArea theInput = new Component.Apex.InputTextArea();
                dynPageBlock.childComponents.add(theInput);
                theInput.styleClass = 'choices';
                theInput.disabled = true;
                if(isFilled){
                    theInput.value = responseByQuestionId.get(q.Id);
                }
                theInput.required = true;

            } else if (questionType == TRUE_FALSE_TYPE) {
                //TODO: add reset button
                Component.Apex.SelectRadio theInput = new Component.Apex.SelectRadio();
                theInput.expressions.value = '{!responseByQuestionId["'+q.Id+'"]}';
                theInput.styleClass = 'choices';
                theInput.required = true;
                theInput.disabled = true;
                List<String> availableOptions = getQuestionChoices(q);
                List<SelectOption> selectOptions = new List<SelectOption>();
                
                for(String choice : availableOptions){
                    SelectOption op = new SelectOption(choice, choice);
                    selectOptions.add(op);
                }
                availableOptionsByQuestionId.put(q.Id, selectOptions);

                Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
                selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["'+q.Id+'"]}';
                theInput.childComponents.add(selectOptionsComponent);

                dynPageBlock.childComponents.add(theInput);
                
                
                
            } else if (questionType == RADIO_TYPE ) {
                Component.Apex.SelectRadio theInput = new Component.Apex.SelectRadio();
                theInput.expressions.value = '{!responseByQuestionId["'+q.Id+'"]}';
                theInput.styleClass = 'choices';
                theInput.required = true;
                theInput.disabled = true;
                
                //test values only:
                List<String> availableOptions = getQuestionChoices(q);
                List<SelectOption> selectOptions = new List<SelectOption>(); // to be used instead of seelctoption component list
                //responseByQuestionId.put(q.Id, 'apple');
                for(String choice : availableOptions){
                    SelectOption op = new SelectOption(choice, choice);
                    selectOptions.add(op);
                }
                availableOptionsByQuestionId.put(q.Id, selectOptions);

                Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
                selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["'+q.Id+'"]}';
                theInput.childComponents.add(selectOptionsComponent);

                dynPageBlock.childComponents.add(theInput);
                
                
                
                
            } else if (questionType == MULTIPLE_CHOICE_TYPE) {
                Component.Apex.SelectCheckboxes theInput = new Component.Apex.SelectCheckboxes();
                List<String> availableOptions = getQuestionChoices(q);//new List<String>{'apple', 'banana', 'carrot'};

                if(isFilled){
                    theInput.expressions.value = '{!selectedOptionsByQuestionId["'+q.Id+'"]}';
                    
                }else{
                    selectedOptionsByQuestionId.put(q.id,availableOptions);
                }
                theInput.styleClass = 'choices';
                theInput.required = true;
                theInput.disabled = true;
                //test values only:
                
                List<SelectOption> selectOptions = new List<SelectOption>(); // to be used instead of seelctoption component list
                //responseByQuestionId.put(q.Id, 'apple');
                for(String choice : availableOptions){
                    SelectOption op = new SelectOption(choice, choice);
                    selectOptions.add(op);
                }
                availableOptionsByQuestionId.put(q.Id, selectOptions);

                Component.Apex.SelectOptions selectOptionsComponent = new Component.Apex.SelectOptions();
                selectOptionsComponent.expressions.value = '{!availableOptionsByQuestionId["'+q.Id+'"]}';
                theInput.childComponents.add(selectOptionsComponent);

                dynPageBlock.childComponents.add(theInput);
            }
            
            
            if(q.Questionfor__c == 'Exam'){
            	
            	
            	Component.Apex.OutputText CorrectAnswerLabel = new Component.Apex.OutputText();
		        CorrectAnswerLabel.value = 'Correct Answer: ' + q.CorrectAnswer__c;
		        //theQuestionLabel.styleClass = 'correctanswer';
		        
		        
		        dynPageBlock.childComponents.add(CorrectAnswerLabel);
		        		        
            }
            
            counter++;
        }
        
        return dynPageBlock;
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
    
}