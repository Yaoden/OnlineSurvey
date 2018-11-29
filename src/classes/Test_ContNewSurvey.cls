@istest
public class Test_ContNewSurvey {

    public static testmethod void testingcontroller(){
       pagereference pageref = page.newsurveycreation;
        test.setCurrentPage(pageref);
        
        contnewsurvey cont = new contnewsurvey(new apexpages.StandardController(new Survey__c()));
		system.assert(cont.pageblock1);
      
        
        //create survey test
        cont.pageblock2=false;
        cont.strsurveyname = 'TestSurvey';
        cont.strsurveyrecordtypeid = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        cont.createsurvey();
        system.assert(cont.pageblock2);
        
        
        //create exam test
        cont.pageblock2=false;
        cont.strsurveyname = 'TestExam';
        cont.strsurveyrecordtypeid = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId();
        cont.showscore = false;
        cont.randomized = false;
        cont.showonequestion = false;
        cont.createsurvey();
        system.assert(cont.pageblock2);
        
        //choose question type
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Short Answer').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        
        //test go back to questions
        cont.pageblock2=false;
        cont.goBackToQuestions();
        system.assert(cont.pageblock2);
        
        //test makenewquestion
        cont.pageblock4 = false;
        cont.makenewquestion();
        system.assert(cont.pageblock4);

        //test link question
        cont.pageblock5 = false;
        cont.linkquestion();
        system.assert(cont.pageblock5);
        
        
        //making new question -- Exam
        cont.questiontypeid = (string)Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId();
		cont.questiontext = 'Test Question';
        cont.questionfortypestr = 'Exam';
        cont.truefalsequestionoutput = 'True';
        cont.insertnewquestion();
        list<question__c> qclist = [select id, question_text__c from question__c];
        system.assertEquals('Test Question', qclist.get(0).question_text__c);
        
        
        
        //making new question -- Survey
        cont.questiontypeid = (string)Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId();
		cont.questiontext = 'Test Question2';
        cont.questionfortypestr = null;
        cont.insertnewquestion();
        list<question__c> qclist2 = [select id, question_text__c from question__c];
        system.assertEquals('Test Question2', qclist2.get(1).question_text__c);
        
        //Linking to old question
        cont.oldquestionid = qclist2.get(0).id;
        cont.pageblock2= false;
        cont.linktooldquestion();
        system.assert(cont.pageblock2);
        
        
        //after chosen survey type
        cont.pageblock1 = true;
        cont.afterchosensurveytype();
        system.assertequals(false,cont.pageblock1);
        
        //delete question
        cont.holdidfordelete = qclist2.get(1).id;
        cont.removetotalquestion();
        qclist2 = [select id, question_text__c from question__c];
        system.assertequals(1, qclist2.size());
       
        
        
    }
}