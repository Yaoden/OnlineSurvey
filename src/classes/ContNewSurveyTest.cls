@istest
public class ContNewSurveyTest {

    public static testmethod void testingcontroller(){
       pagereference pageref = page.newsurveycreation;
        test.setCurrentPage(pageref);
        
        contnewsurvey cont = new contnewsurvey(new apexpages.StandardController(new Survey__c()));
      
        
        //create survey test
        cont.strsurveyname = 'TestSurvey';
        cont.strsurveyrecordtypeid = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        cont.createsurvey();
        
        
        //create exam test
        cont.strsurveyname = 'TestExam';
        cont.strsurveyrecordtypeid = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Exam').getRecordTypeId();
        cont.showscore = false;
        cont.randomized = false;
        cont.showonequestion = false;
        cont.createsurvey();
        System.assertEquals(2,[select count() from survey__c]);
        
        
        //choose question type and check to see if the correct page is returned from choosewhichquestiontypetocreate()
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Radio').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        cont.questiontypeid = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Short Answer').getRecordTypeId();
        cont.choosewhichquestiontypetocreate();
        
        //test go back to questions
        cont.goBackToQuestions();
        
        
        //test makenewquestion
        cont.goBackToCreateQuestions();

        //test link question
        cont.linkquestion();
        
        
        //making new question -- Exam
        cont.questiontypeid = (string)Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('Multiple Choice').getRecordTypeId();
		cont.questiontext = 'Test Question';
        cont.questionfortypestr = 'Exam';
        cont.questiona = 'a';
        cont.questionb = 'b';
        cont.questionc = 'c';
        cont.questiond = 'd';
        cont.questione = 'e';
        cont.correctanswer = 'b';
        
        cont.insertnewquestion();
        list<question__c> qclist = [select id, question_text__c from question__c];
        system.assertEquals('Test Question', qclist.get(0).question_text__c);
        
        
        
        //making new question -- Survey
        cont.questiontypeid = (string)Schema.SObjectType.Question__c.getRecordTypeInfosByName().get('True/False').getRecordTypeId();
		cont.questiontext = 'Test Question2';
        cont.questionfortypestr = 'Exam';
        cont.truefalsequestionoutput = 'False';
        cont.insertnewquestion();
        list<question__c> qclist2 = [select id, question_text__c from question__c];
        system.assertEquals('Test Question2', qclist2.get(1).question_text__c);
        
        //Linking to old question
        cont.oldquestionid = qclist2.get(0).id;
        cont.linktooldquestion();
        
        
        //after chosen survey type
        cont.afterchosensurveytype();
        
        //delete question
        cont.holdidfordelete = qclist2.get(1).id;
        cont.removetotalquestion();
        qclist2 = [select id, question_text__c from question__c];
        system.assertequals(1, qclist2.size());
       
        
        
    }
}