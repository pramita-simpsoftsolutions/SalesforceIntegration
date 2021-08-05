public class APTS_ViewDiscountHierarchy{
    public Apttus_Proposal__Proposal__c objProposal {get;set;}
    public APTS_Discount_Hierarchy_Header__c objDHH{get;set;}
    public List<APTS_Discount_Hierarchy__c> liDH {get;set;}
    //public List<APTS_Discount_Hierarchy_Header__c> liDHH {get;set;}
    public List<APTS_Discount_Hierarchy_Products__c> liDHP {get;set;}
    public Boolean showData{get;set;}
    public String CallingMode{get;set;}
    public String AccountName{get;set;}
    public String ProposalName{get;set;}
    public String PricelistName{get;set;}
    public String errorMessage{get;set;}
    public Boolean showErrorMessage{get;set;}
    public Map<String, Decimal> mapPGtoTCV { get; set; }
    
    public APTS_ViewDiscountHierarchy(){
        showData = true;
        CallingMode = ApexPages.currentPage().getParameters().get('CallingMode') ;
        mapPGtoTCV = new Map<String,Decimal>();
        Id ProposalId;
        
        if(CallingMode !=null && CallingMode == 'Proposal'){
            ProposalId = ApexPages.currentPage().getParameters().get('id');
            List<Apttus_Proposal__Proposal__c> liProposal = [Select Id,Name,Apttus_QPConfig__PriceListId__r.APTS_Pricebook_id__c,
                                                            Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c,Apttus_QPConfig__PriceListId__r.Name,
                                                            Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__r.Name from Apttus_Proposal__Proposal__c WHERE id=:ProposalId];
            
            List<APTS_Discount_Hierarchy_Header__c> liDHH = [select Id, Name, APTS_Parent_Account__c ,APTS_Parent_Account__r.Name, APTS_PriceListId__c,APTS_PriceListId__r.Name, APTS_PriceListId__r.APTS_Pricebook_id__c,
            APTS_ProposalID__r.APTS_ILS__c,APTS_ProposalID__r.APTS_VIP_Catalog__c,APTS_ProposalID__r.APTS_SAM__c ,APTS_ProposalID__r.APTS_Standard__c,APTS_ProposalID__r.APTS_SQW_Exception__c ,
            APTS_ProposalID__c,APTS_ProposalID__r.Name, APTS_Opportunity__c, APTS_Default_Discount__c, APTS_Bypass_Default_Discount_Validation__c, 
            APTS_Has_PriceList_Mapping_Mismatch__c, APTS_Discount_Hierarchy_Header__c, APTS_Previous_Discount_Hierarchy_Header__c, 
            APTS_Total_Estimated_TCV__c, APTS_Discount_Hierarchy_Name__c from APTS_Discount_Hierarchy_Header__c 
            WHERE APTS_ProposalID__c =:ApexPages.currentPage().getParameters().get('id')];
            if(liDHH.size()  == 0){
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No Discount Hierarchy has been defined yet'));
                showData = false;
            }
            objDHH = new APTS_Discount_Hierarchy_Header__c();
            liDH = new List<APTS_Discount_Hierarchy__c>();
            if(liDHH.size() >0){
                if(liDHH[0].APTS_PriceListId__r.APTS_Pricebook_id__c != liProposal[0].Apttus_QPConfig__PriceListId__r.APTS_Pricebook_id__c){
                    showErrorMessage = true;
                    errorMessage = 'Price List has been Changed. Please update Discount hierarchy from the cart.';
                }
                objDHH = liDHH[0];
                AccountName = objDHH.APTS_Parent_Account__r.Name;
                ProposalName = objDHH.APTS_ProposalID__r.Name;
                if(liProposal[0].Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c !=null){
                    PricelistName = liProposal[0].Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__r.Name;
                }else{
                    PricelistName = liProposal[0].Apttus_QPConfig__PriceListId__r.Name;
                }
                //PricelistName = objDHH.APTS_PriceListId__r.Name;
            }else{
                //Add Error Message to the page saying no DH exist. Go back
            }
            if(objDHH.Name !=null){
                //get DH and DHProducts
                liDH = [select Id, OwnerId, IsDeleted,APTS_Product_Group_Master__r.Name, Name,  APTS_Discount_Hierarchy_Header__c, APTS_Is_Product_Available__c, APTS_Business_Group_master__c, APTS_Product_Group_Master__c, APTS_External_family__c, APTS_Product_Sector_Family__c, APTS_Discount__c, APTS_PG_Estimated_TCV__c, APTS_Display_Name__c, APTS_Not_Found_in_Updated_PriceList__c, APTS_Added_in_Recent_Price_List__c, APTS_Discount_Defaulted__c, APTS_Discount_from_PG__c, APTS_Is_Manual_Discount_Given__c, APTS_Level__c, APTS_Available_Pricebook__c, APTS_Quote_Proposal__c from APTS_Discount_Hierarchy__c WHERE APTS_Discount_Hierarchy_Header__c =:objDHH.Id ORDER BY APTS_Business_Group_master__r.Name,APTS_Product_Group_Master__r.Name,APTS_External_family__c];
                liDHP = [select Id, APTS_Product_Code__c,Name, APTS_Discount_Hierarchy_Header__c, APTS_Price_List_Item__c, APTS_ProductID__c, APTS_Product_Description__c, APTS_Discount__c, APTS_Royalty_Flag__c, APTS_Maximum_Discount__c, APTS_Price_List__c, APTS_Quote__c from APTS_Discount_Hierarchy_Products__c WHERE APTS_Discount_Hierarchy_Header__c =:objDHH.Id];
            }
        }else if(CallingMode !=null && CallingMode == 'DHHeader'){
            showData = true;
            List<APTS_Discount_Hierarchy_Header__c> liDHH = [select Id, Name, APTS_Parent_Account__c ,APTS_Parent_Account__r.Name, APTS_PriceListId__c,APTS_PriceListId__r.Name, 
            APTS_ProposalID__r.APTS_ILS__c,APTS_ProposalID__r.APTS_VIP_Catalog__c,APTS_ProposalID__r.APTS_SAM__c ,APTS_ProposalID__r.APTS_Standard__c,APTS_ProposalID__r.APTS_SQW_Exception__c ,
            APTS_ProposalID__c,APTS_ProposalID__r.Name, APTS_Opportunity__c, APTS_Default_Discount__c, APTS_Bypass_Default_Discount_Validation__c, 
            APTS_Has_PriceList_Mapping_Mismatch__c, APTS_Discount_Hierarchy_Header__c, APTS_Previous_Discount_Hierarchy_Header__c, 
            APTS_Total_Estimated_TCV__c, APTS_Discount_Hierarchy_Name__c,APTS_ProposalID__r.Apttus_QPConfig__PriceListId__r.Name,APTS_ProposalID__r.Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__r.Name from APTS_Discount_Hierarchy_Header__c 
            WHERE Id =:ApexPages.currentPage().getParameters().get('id')];
            if(liDHH.size()  == 0){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No Discount Hierarchy has been defined yet'));
                showData = false;
            }
            objDHH = new APTS_Discount_Hierarchy_Header__c();
            liDH = new List<APTS_Discount_Hierarchy__c>();
            if(liDHH.size() >0){
                objDHH = liDHH[0];
                AccountName = objDHH.APTS_Parent_Account__r.Name;
                proposalId = objDHH.APTS_ProposalID__c;
                ProposalName = objDHH.APTS_ProposalID__r.Name;
                if(objDHH.APTS_ProposalID__r.Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c !=null){
                    PricelistName = objDHH.APTS_ProposalID__r.Apttus_QPConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__r.Name ;
                }else{
                    PricelistName = objDHH.APTS_ProposalID__r.Apttus_QPConfig__PriceListId__r.Name;
                }
                //PricelistName = objDHH.APTS_PriceListId__r.Name;
            }else{
                //Add Error Message to the page saying no DH exist. Go back
            }
            if(objDHH.Name !=null){
                //get DH and DHProducts
                liDH = [select Id, OwnerId,APTS_Product_Group_Master__r.Name, IsDeleted, Name,  APTS_Discount_Hierarchy_Header__c, APTS_Is_Product_Available__c, APTS_Business_Group_master__c, APTS_Product_Group_Master__c, APTS_External_family__c, APTS_Product_Sector_Family__c, APTS_Discount__c, APTS_PG_Estimated_TCV__c, APTS_Display_Name__c, APTS_Not_Found_in_Updated_PriceList__c, APTS_Added_in_Recent_Price_List__c, APTS_Discount_Defaulted__c, APTS_Discount_from_PG__c, APTS_Is_Manual_Discount_Given__c, APTS_Level__c, APTS_Available_Pricebook__c, APTS_Quote_Proposal__c from APTS_Discount_Hierarchy__c WHERE APTS_Discount_Hierarchy_Header__c =:objDHH.Id ORDER BY APTS_Business_Group_master__r.Name,APTS_Product_Group_Master__r.Name,APTS_External_family__c];
                liDHP = [select Id, Name, APTS_Product_Code__c,APTS_Discount_Hierarchy_Header__c, APTS_Price_List_Item__c, APTS_ProductID__c, APTS_Product_Description__c, APTS_Discount__c, APTS_Royalty_Flag__c, APTS_Maximum_Discount__c, APTS_Price_List__c, APTS_Quote__c from APTS_Discount_Hierarchy_Products__c WHERE APTS_Discount_Hierarchy_Header__c =:objDHH.Id];
            }
        }
        
        //PGL Development for CPQ-3882 starts
        List<Apttus_Config2__LineItem__c> liLineItems = [select Id,Name,APTS_Product_Group__c, APTS_Net_Price__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__VersionNumber__c from Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c  = :proposalID ORDER BY Apttus_Config2__ConfigurationId__r.Apttus_Config2__VersionNumber__c DESC];
        Decimal LatestversionNumber = liLineItems.size() >0 ? liLineItems[0].Apttus_Config2__ConfigurationId__r.Apttus_Config2__VersionNumber__c : 0;
        for(Apttus_Config2__LineItem__c objLI : liLineItems){
            if(LatestversionNumber == objLI.Apttus_Config2__ConfigurationId__r.Apttus_Config2__VersionNumber__c){
                Decimal TCVforthisPG = 0;
                if(!mapPGtoTCV.containsKey(objLI.APTS_Product_Group__c)){
                    mapPGtoTCV.put(objLI.APTS_Product_Group__c , objLI.APTS_Net_Price__c);
                }else{
                    TCVforthisPG = mapPGtoTCV.get(objLI.APTS_Product_Group__c);
                    TCVforthisPG += objLI.APTS_Net_Price__c;
                    mapPGtoTCV.put(objLI.APTS_Product_Group__c , TCVforthisPG);
                }
            }            
        }
        
        for(APTS_Discount_Hierarchy__c objDH : liDH){
            if(!mapPGtoTCV.containsKey(objDH.APTS_Product_Group_Master__r.Name)){
                mapPGtoTCV.put(objDH.APTS_Product_Group_Master__r.Name , 0);
            }
        }
        
        //PGL Development for CPQ-3882 ends
    
    }

    public PageReference goToQuote()
    {
            String instanceURL ;
            Apttus_Config2__ConfigSystemProperties__c csValue = Apttus_Config2__ConfigSystemProperties__c.getValues('System Properties') ;
            if(csValue !=null){
                instanceURL = csValue.Apttus_Config2__InstanceUrl__c;
            }
            Pagereference  returnTo = new Pagereference(instanceURL+'/'+ApexPages.currentPage().getParameters().get('id'));
            returnTo.setRedirect(true); 
            return returnTo;
    }

}