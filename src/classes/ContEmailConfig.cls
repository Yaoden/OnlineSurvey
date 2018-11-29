public with sharing class ContEmailConfig{
    public list<Contact> lstcont{get;set;}
    public integer icountsize{get;set;}
    //public string strsubject{get;set;}
    //public string strbody{get;set;}
    //public boolean showblock1{get;set;}
    //public boolean showblock2{get;set;}
    public string surveyid{get;set;}
    public list<Survey__c> surveyoptions{get;set;}
    public list<SelectOption> surveys{get;set;}
    public string tempremoval{get;set;}
    public ContEmailConfig(ApexPages.StandardSetController controller) {
        
        lstcont=[select id, firstname, lastname, email from contact where id in:controller.getselected()];
        surveyoptions=[select id, name from Survey__c];
        surveys=new list<SelectOption>();
        for(Survey__c temp : surveyoptions)
        {
            surveys.add(new SelectOption(temp.Id, temp.name));
        }
        
        
        
        icountsize=lstcont.size();
        
        //showblock1=true;
        //showblock2=false;
    }
    
    
    //Need to create a redirect after the user hits send
    public PageReference emailsending(){

        list<SurveyResponse__c> lstsurveyresponses = new list<SurveyResponse__c>();
        //List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); 
        //list<string> lsttempaddress = new list<string>();
        
        for(contact c:lstcont){
            SurveyResponse__c survey = new SurveyResponse__c();
            survey.Survey__c = surveyId ;
            survey.Contact__r   = c;
            survey.Contact__c   = c.id;
            survey.Survey_Status__c = 'Sent';
            lstsurveyresponses.add(survey);

        }
        insert lstsurveyresponses;
        /*
        for(SurveyResponse__c c: lstsurveyresponses){
           lsttempaddress.add(c.contact__r.email);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(strsubject);
            email.setHTMLBody('<html><h1>' + 'Please Take your Survey</h1><p>'+ strbody +'</p><a href="' + System.Label.DynamicSurveyURL + c.id + '">Take survey here</a><html>');
            email.toaddresses = lsttempaddress;
            emails.add(email);
            lsttempaddress.clear();
        }
        
        Messaging.SendEmailResult [] result = Messaging.sendEmail(emails);
        */
        PageReference nextPage = new PageReference('/apex/sentSurvey');
        nextPage.setRedirect(true);
        return nextPage;
        
      
        
    }
    
    /*
     * Deprecated
    public void movetonextpart(){
        showblock1=false;
        showblock2=true;
    }
    public void previoussection(){
        showblock1=true;
        showblock2=false;
    }
    */
    //list size isn't dynamically checked on each page load
    public void removefromlist(){
        for(Integer j = 0; j < lstcont.size(); j++){
            if(lstcont.get(j).id == (tempremoval)){
                lstcont.remove(j);
                icountsize--;
            }
        }
        
    }
    
    
}