public class EMP_PortalPageComponent_Controller {
    public Page_Component__c PageComponent  {get;set;}
    public EMP_PortalPageComponent_Controller(ApexPages.StandardController controller) {
        PageComponent = (Page_Component__c)controller.getRecord();
    }
    public pagereference save(){
        insert PageComponent;
        return null;
    }
    
}