public class ControllerSurveySummary {
    public String surveyid{get;set;}
    public String surveyName{get;set;}
    public Survey__c surv{get;set;}
    public Map<Id, QuestionWrapper> questionData{get;set;}

    public ControllerSurveySummary(ApexPages.StandardController stdcontroller){
    	
    	//surv = (Survey__c) stdcontroller.getRecord();
    	surv = [select id,name from Survey__c where id =: stdcontroller.getRecord().id limit 1];
    	surveyid = surv.id;
    	surveyName = surv.Name;
    	
        setupData();
    }

    public void setupData(){

        List<Id> questionIds = new List<Id>();
        List<Question__c> questions = new List<Question__c>();
        List<SurveyJoinQuestion__c> joins = [
            SELECT Id, Question__c FROM SurveyJoinQuestion__c
            WHERE Survey__c = :surveyid
        ];
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'joins: '+joins.size()));

        for(SurveyJoinQuestion__c j : joins){
            questionIds.add(j.Question__c);
        }
        questions = [
            SELECT Id, RecordType.Name, Question_Text__c, Choice_A__c, Choice_B__c, Choice_C__c, Choice_D__c, Choice_E__c
            FROM Question__c
            WHERE Id IN :questionIds AND RecordType.Name != 'Short Answer'
        ];
        List<AggregateResult> totals = [
            SELECT Question__c, COUNT(Id) cnt, TextFieldAnswer__c
            FROM Answers__c
            WHERE Question__c IN :questions AND SurveyResponse__r.Survey__c = :surveyId
            GROUP BY Question__c, TextFieldAnswer__c
        ];
        questionData = new Map<Id, QuestionWrapper>();

        for(Question__c q : questions){
            questionData.put(q.Id, new QuestionWrapper(q));
        }

        for(AggregateResult r : totals){
            questionData.get((Id)r.get('Question__c')).choicesTotals.put((String)r.get('TextFieldAnswer__c'), (Integer)r.get('cnt'));
        }
    }

    public String getJSONResults(){
        if(questionData != null)
            return JSON.serialize(questionData.values());
        return null;
    }
    public List<QuestionWrapper> getResults(){
        if(questionData != null)
            return questionData.values();
        return null;
    }

    private class QuestionWrapper{
        public Id id{get;set;}
        public String text{get;set;}
        public String recordType{get;set;}
        public Map<String, Integer> choicesTotals{get;set;}

        public QuestionWrapper(Question__c question){
            id = question.Id;
            text = question.Question_Text__c;
            recordType = question.RecordType.Name;
            choicesTotals = new Map<String, Integer>();

            if(question.RecordType.Name == 'True/False'){
                choicesTotals.put('True', 0);
                choicesTotals.put('False', 0);
            }

            if(question.Choice_A__c != null)
                choicesTotals.put(question.Choice_A__c, 0);
            if(question.Choice_B__c != null)
                choicesTotals.put(question.Choice_B__c, 0);
            if(question.Choice_C__c != null)
                choicesTotals.put(question.Choice_C__c, 0);
            if(question.Choice_D__c != null)
                choicesTotals.put(question.Choice_D__c, 0);
            if(question.Choice_E__c != null)
                choicesTotals.put(question.Choice_E__c, 0);
        }
    }
}