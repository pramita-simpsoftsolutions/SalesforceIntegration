/**
* @author Cadence
*
* @group ECOMCOS
*
* @description  This class is used to perform the COS Auto-registraion 
*               for the user who purchased SAAS License
*/
public class ECommEntitlementService {

    /**
     * A future method to perform COS auto registration for the user who purchased SAAS 
     * License. This method gets called on after insert of entitlement record where  
     * Entitlement Source is equal to 'eCommerce' and User Okta Id is present.
     */
    @future
    public static void eComAutoRegstrtnEntAssctn(Set<Id> newParentEntId){
        List<Entitlement> newEntitlementList = new List<Entitlement>();
        newEntitlementList=[select id, Name, Status__C, Product_Status__c, Maintenance_Status__c, Entitlement_Source__c, Entitlement_End_Date__c, Type, Parent_Entitlement__r.id, 
                            User_Okta_ID__c, Locking_Id__c, Parent_Account__c, AccountId from Entitlement where (Parent_Entitlement__r.id in:newParentEntId or Id in:newParentEntId) Limit 45000];
        
        List<Entitlement> eComEntList = new List<Entitlement> (); 
        Map<Id,String> parentEntUserMap = new Map<Id,String>();
        Map<String,String> eComKeyUsrIdMap = new Map<String,String>();
        Map<String, String> supportEnt = new Map<String, String>(); 
        String refKeyParentID = CadenceSSOConfiguration__c.getValues('REFKEYPARENTACCOUNTID').Value__c;
        for (Entitlement ent : newEntitlementList){
          if(ent.Entitlement_Source__c != '' && ent.Entitlement_Source__c != null && ent.Entitlement_Source__c == Label.eCom_App_Name && ent.User_Okta_ID__c!= '' && ent.User_Okta_ID__c!= null){
            eComEntList.add(ent);
            parentEntUserMap.put(ent.Parent_Entitlement__r.Id,ent.User_Okta_ID__c);
            eComKeyUsrIdMap.put(ent.User_Okta_ID__c,ent.Locking_Id__c);
            if(ent.type == 'Phone, Web and Email'){
                supportEnt.put(ent.User_Okta_ID__c,ent.Locking_Id__c);
            }
          }
        }
        Map<Id, Contact> eComContact = new Map<Id, Contact>();
        try{
            eComContact = new Map<Id, Contact>([Select Id, Email, Salutation, Contact_Number__c, FirstName, LastName, Name, AccountId, Account.Name, Parent_Account__c, Middle_Name__c, Active_Status__c, 
                                                Fax, Phone, Cellular_Phone__c, Extension__c, Street__c, Login_Name__c, COS_Registration_Date__c, Validation_Status__c, Validated_Date__c,
                                                Sourcelink_ID__c, Okta_Id__c, COS_LOS_Users__c, Parent_Account__r.Name, City__c, Country__r.name, State_Region__r.name, Postal_Code__c, 
                                                Job_Title__c, Host_ID__c, Reference_Key__r.name, LMS_Key__c, LMS_Active__c from Contact where Okta_Id__c in : eComKeyUsrIdMap.keySet()]); 
        } catch(QueryException ex){
            AsyncExceptionUtil.addtoErrorLog(newEntitlementList, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'eComAutoRegstrtnEntAssctn', 'Okta User Id of Entitlement is not found in any Contact');
        }
        createSuprtTcktNonPrcssdRcrd(eComContact,eComKeyUsrIdMap);   
        Map<String,User> inActvUsr = new Map <String, User>();
        List<Contact> losCon = new List<Contact>();
        List<Contact> inActvCon = new List<Contact>();
        Map<Id,String> eComKeyLOSConIdMap = new Map<Id,String>();
        for(Contact con : eComContact.values()){
            //Check for LOS Contact
            if(con.Parent_Account__c == refKeyParentID && con.COS_LOS_Users__c == true && con.Active_Status__c == true){
                losCon.add(con);
                eComContact.remove(con.Id);
                if(eComKeyUsrIdMap.get(con.Okta_Id__c)!= null){
                    eComKeyLOSConIdMap.put(con.Id, eComKeyUsrIdMap.get(con.Okta_Id__c));
                }
                
            }
            //Check for Inactive Contact
            if(con.Active_Status__c == false){
                inActvCon.add(con);
                eComContact.remove(con.Id);
            }
        }
        if(inActvCon.size() > 0){
            ECommEntitlementServiceUtility.sendNotificationToDataQuality(inActvCon, eComKeyUsrIdMap);
        } 
        if(losCon.size()> 0){
            createSSGTaskForLOSUser(losCon, eComKeyLOSConIdMap);
        }
        if(supportEnt.size() > 0 && eComContact.size() > 0){
            Map<Id,Contact> cosContact = new Map<Id,Contact>();
            for(Contact supportCont :eComContact.values()){
                if(supportEnt.get(supportCont.Okta_Id__c) != null){
                    cosContact.put(supportCont.Id, supportCont);
                }    
            }
            if(cosContact.size() > 0){
                Map<Id, User> eComUsr = new Map <Id, User>([Select Id, Name, Email, isActive, ContactId from User where ContactId in : cosContact.keySet()]);
                List<Contact> conWithUsr = new List<Contact>(); 
                if(eComUsr.size() == 0){
                    createCommunityUser(cosContact.values(), null);
                    createTaskOnCOSRegistration(cosContact.values(), eComKeyUsrIdMap);
                } else if (eComUsr.size() > 0){
                    for(User usr : eComUsr.values()){
                        if(cosContact.get(usr.ContactId) == null)
                            conWithUsr.add(cosContact.get(usr.ContactId));
                        else if (cosContact.get(usr.ContactId)!= null && usr.isActive == false)
                            inActvUsr.put(usr.ContactId, usr);
                    }
                    createCommunityUser(conWithUsr, inActvUsr);
                    createTaskOnCOSRegistration(conWithUsr, eComKeyUsrIdMap);
                }

            }
        }
        if(eComContact.size()>0){
           eComContactUpdate(eComContact.values());   
           if(eComContact != null && eComContact.size() > 0 && parentEntUserMap != null && parentEntUserMap.size() > 0){
              associateEntitlementContact(eComContact.values(), parentEntUserMap);
           }
           if(eComContact != null && eComContact.size() > 0 && newEntitlementList.size() > 0){
            updateEntitlemntAccWithConAcc(eComContact.values(), newEntitlementList);
           }
        }
    }  

   /**
   * Method to update COS registration specific fields on Contact to leverage COS login.
   */
    public static void eComContactUpdate(List<Contact> conList){
        List<Contact> updateContact = new List<Contact>();
        for(Contact con : conList){
            if(con.COS_Registration_Date__c == null || con.Sourcelink_ID__c == null || con.Sourcelink_ID__c =='' || (con.Sourcelink_ID__c != '' 
               && con.Sourcelink_ID__c != null && con.Email != null && con.Email != '' && ((con.Email.contains('@cadence.com') && con.Sourcelink_ID__c != con.Email.split('@')[0]) 
                                                                                        ||(!con.Email.contains('@cadence.com') && con.Sourcelink_ID__c != con.Email)))){

                if(con.COS_Registration_Date__c == null){
                   con.Validation_Status__c = null;
                   con.Validated_Date__c = null;
                   con.COS_Registration_Date__c = DateTime.Now();
                   con.EComm_to_COS_Role_Update__c = true;
                }
                if(con.Sourcelink_ID__c == null || con.Sourcelink_ID__c =='' || (con.Sourcelink_ID__c != '' 
                  && con.Sourcelink_ID__c != null && con.Email != null && con.Email != '' && 
                  ((con.Email.contains('@cadence.com') && con.Sourcelink_ID__c != con.Email.split('@')[0]) 
                  ||(!con.Email.contains('@cadence.com') && con.Sourcelink_ID__c != con.Email)))){
                     if(con.Email.contains('@cadence.com')){
                        con.Sourcelink_ID__c = con.Email.split('@')[0];
                     } else {
                        con.Sourcelink_ID__c = con.Email;  
                     }
                      
                }
                updateContact.add(con);
            }
        }
        if(updateContact.size() > 0){
            String failedReport ='';
            ContactTriggerHandler_AC.bypassUnifiedUser = true;  
            System.debug('Test ContactList::::::::'+updateContact);
            try{
                Database.SaveResult[] results = Database.update(updateContact,false);   
                String errorMessage ='';
                for(Integer i=0;i<results.size();i++){
                    String failedErrors='';
                    if (!results.get(i).isSuccess()){
                        failedErrors+= 'Failed Contact Email: '+updateContact[i].Name + ' : ';
                        failedErrors+= 'Okta Id:'+updateContact[i].Okta_Id__c + '-->';
                        for(Database.Error theError: results.get(i).getErrors()){  
                            errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                            failedErrors += (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                            failedErrors += ',';
                        }
                        failedErrors = failedErrors.removeEnd(',');
                    } 
                    if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                    }
                }
                if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null)){
                    ECommEntitlementServiceUtility.createException('eComContactUpdate', 'Update ECOM Contact to leverage COS Login', errorMessage, failedReport);
                }
                   
            } catch (Exception ex) {
                AsyncExceptionUtil.addtoErrorLog(updateContact, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'eComContactUpdate', 'Update ECOM Contact to leverage COS Login');
            }    
            ContactTriggerHandler_AC.bypassUnifiedUser = false;    
        }
    }

    /**
     * Method to create community record for the user who purchased SAAS License 
     * to leverage the login to COS Application.
     */
    public static void createCommunityUser(List<Contact> conList, Map<String,User> inActvUsr)
       {   
          List<User> communityUsr = new List<User>();
          UserTriggerHandler_AC.ProvUSER_BYPASS = true;
          UserTriggerHandler_AC.USER_BYPASS = true;
          Database.DMLOptions dmo = new Database.DMLOptions();
          dmo.emailHeader.triggerUserEmail = false;
          for(Contact conu : conList){ 
          if(inActvUsr != null && inActvUsr.get(conu.Id)!= null)
          {
            User u = createCommunityRecord(conu);
            communityUsr.add(u);
          }else if(!conu.Email.contains('@cadence.com')){
            User u = createCommunityRecord(conu);
            communityUsr.add(u);
            System.debug('>>>>>>>>>>>user Detail>>>>>>>>>'+u);
          }
        }
        if(communityUsr.size() > 0 ){
            String failedReport = '';
            try{
                Database.UpsertResult[] results = Database.upsert(communityUsr,false); 
                String errorMessage = '';
                for(Integer i=0;i<results.size();i++){
                    String failedErrors='';
                    if (!results.get(i).isSuccess()){
                        failedErrors+= 'Failed User Email: '+communityUsr[i].Email + ' : ';
                        failedErrors+= 'Contact Id:'+communityUsr[i].ContactId + '-->';
                        for(Database.Error theError: results.get(i).getErrors()){  
                            errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                            failedErrors+= (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                            failedErrors += ',';
                        }
                        failedErrors = failedErrors.removeEnd(',');
                    } 
                    if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                    }
                }
                if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null))
                {
                    ECommEntitlementServiceUtility.createException('createCommunityUser', 'COS Community User Creation for EComm User', errorMessage, failedReport);
                }             
            } catch(Exception ex) {
                AsyncExceptionUtil.addtoErrorLog(communityUsr, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'eComContactUpdate', 'Update ECOM Contact to leverage COS Login');
            }    
        }
        UserTriggerHandler_AC.USER_BYPASS = false;
        UserTriggerHandler_AC.ProvUSER_BYPASS = false;
      }

      /**
       * Method to associate SAAS Entitlement to respective Contact who's Okta ID is present
       * in SAAS entitlement record.
       */
      public static void associateEntitlementContact(List<Contact> conList, Map<Id,String> parentEntUsrMap){
          Map<String,Contact> oktaIdContactMap = new Map<String,Contact>();
          Map<Id,Id> entContIdMap = new Map<Id,Id>();
          List<EntitlementContact> newEntConList = new List<EntitlementContact>();
          for(Contact con : conList){
            oktaIdContactMap.put(con.Okta_Id__c, con);
            System.debug('oktaIdContactMap**'+oktaIdContactMap);
          }
          for(EntitlementContact exstngEntCon : [select id, contactid, EntitlementId from EntitlementContact where EntitlementId =: parentEntUsrMap.keyset()]){
            entContIdMap.put(exstngEntCon.EntitlementId,exstngEntCon.contactid);
          }
          for(Id entId : parentEntUsrMap.keyset()){ 
            if(entContIdMap != null && entContIdMap.size() > 0 && oktaIdContactMap != null && entContIdMap.get(entId) == oktaIdContactMap.get(parentEntUsrMap.get(entId)).Id){
                continue;
            } else if(oktaIdContactMap.size() > 0){ 
                EntitlementContact entConRec = new EntitlementContact();
                entConRec.EntitlementId = entId;
                entConRec.ContactId = oktaIdContactMap.get(parentEntUsrMap.get(entId)).Id;
                newEntConList.add(entConRec);
                System.debug('entConRec**'+entConRec);
             }

         }
         if(newEntConList.size() > 0){
            String failedReport ='';
            try{
                Database.SaveResult[] results = Database.insert(newEntConList,false); 
                String errorMessage = '';
                for(Integer i=0;i<results.size();i++){
                    String failedErrors='';
                    if (!results.get(i).isSuccess()){
                        failedErrors+= 'Failed to associate Entitlement Id: '+newEntConList[i].EntitlementId + ' : ';
                        failedErrors+= 'Contact Id:'+newEntConList[i].ContactId + '-->';
                        for(Database.Error theError: results.get(i).getErrors()){  
                            errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                            failedErrors+= (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                            failedErrors += ',';
                        }
                        failedErrors = failedErrors.removeEnd(',');
                    } 
                    if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                    }
                }
                if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null))
                {
                    ECommEntitlementServiceUtility.createException('associateEntitlementContact', 'EntitlementContact record creation for EComm Contact', errorMessage, failedReport);
                }       
            } catch(Exception ex) {
                AsyncExceptionUtil.addtoErrorLog(newEntConList, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'associateEntitlementContact', 'Insert EntitlementContact');
            }  
         } 
    } 

    /**
    * Method to create task for data quality user if LOS user purchases SAAS license.
    */
    public static void createSSGTaskForLOSUser(List<Contact> losConList, Map<Id,String> eComKeyConIdMap){
        List<Task> taskList = new list<Task>();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.emailHeader.triggerUserEmail = false;   
        String subject = 'Attn: SSG/CRC - ECOM Account Created';
        String activityType = 'ECOM Contact Creation';       
		CadenceSSOConfiguration__c cadqueueid = CadenceSSOConfiguration__c.getValues('CadenceCOSQueueid'); 
		for(contact con : losConList)
		{
			if(con.id != null && con.Reference_Key__c != null)
			{
                Task t = createTaskRecord(con, subject, activityType, cadqueueid.Value__c, eComKeyConIdMap.get(con.id));
            	taskList.add(t);
     		}
        }     
            System.debug('task'+taskList); 
            List<Contact> updatedConList =  new List<Contact>();  
			TaskTriggerHandler_AC.isPopulateSubmitterInfo = false;
            if(taskList.size() > 0){
                String failedReport ='';
                try{
                    Database.SaveResult[] results = Database.insert(taskList, dmo); 
                    String errorMessage = '';
                    for(Integer i=0;i<results.size();i++){
                        if (results.get(i).isSuccess()) {
                            updatedConList.add(losConList[i]);
                        }
                        String failedErrors='';
                        if (!results.get(i).isSuccess()){
                            failedErrors+= 'Failed to create task: '+taskList[i].Description + ' : ';
                            failedErrors+= 'Activity Type:'+taskList[i].Activity_Type__c + '-->';
                            for(Database.Error theError: results.get(i).getErrors()){  
                                 errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                                 failedErrors+= (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                                 failedErrors += ',';
                            }
                            failedErrors = failedErrors.removeEnd(',');
                        } 
                        if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                        }
                    }
                    if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null)){
                        ECommEntitlementServiceUtility.createException('createSSGTaskForLOSUser', 'Create Task for SSG to update LOS to ECommLicense', errorMessage, failedReport);
                    }       
                } catch(Exception ex) {
                    AsyncExceptionUtil.addtoErrorLog(taskList, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'createSSGTaskForLOSUser', 'Create Task for SSG to update LOS to ECommLicense');
                }
            }    
			TaskTriggerHandler_AC.isPopulateSubmitterInfo = true;
            if (updatedConList.size() > 0) {
                sendEmailToSSGForLOSUsr(updatedConList, subject, activityType, eComKeyConIdMap);
            }  
    }

    /**
     * Method to send notification to data quality user on creation of task for LOS User 
     * SAAS license.
     */
    public static void sendEmailToSSGForLOSUsr(List<Contact> losConList, String subject, String activityType, Map<Id,String> eComKeyConIdMap){
        List<Messaging.SingleEmailMessage> mailListToSend = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail;
        list<string>  toAddress = new list<string>();
        toAddress.addAll(CadenceMyProfileController1.gettingUsers('Data_Quality'));
        String orgId;
        Support_Address__c sa = Support_Address__c.getValues('NO_REPLY');
        for(OrgWideEmailAddress owa : [select id, Address from OrgWideEmailAddress where address =: sa.EmailAddress__c]) {                          
            orgId = owa.id;
        }
        for(Contact con : losConList){
            mail = new Messaging.SingleEmailMessage(); 
            mail.setToAddresses(toAddress);
            mail.setOrgWideEmailAddressId(orgId);
            mail.setSubject(subject); 
            String HtmlBody = '<html>';
            HtmlBody = HtmlBody + '<br/> Subject: '+ subject + '<br/>';
            HtmlBody = HtmlBody + 'Activity Type: ' + activityType + '<br/>';
            HtmlBody = HtmlBody + populateDescription(con, eComKeyConIdMap.get(con.id), true);
            HtmlBody = HtmlBody + 'Thank you,<br/>';
            HtmlBody = HtmlBody +' Cadence Support Team<br/>';  
            
            mail.setHtmlBody(HtmlBody);
            mailListToSend.add(mail);
        }
        try{
        	Messaging.sendEmail(mailListToSend);    
        } catch(System.EmailException e){
            System.debug('Following exception has occurred during send emails to Employees: ' + e.getMessage());
		}
    }

    /**
     * Method to upadate Entitlement's Parent Account/Account with respective Contact's 
     * Parent Account/Account when it gets associted with a Contact.
     */
    public static void updateEntitlemntAccWithConAcc(List<Contact> conList, List<Entitlement> newEntitlementList){
        Map<String, Contact> okatIdConMap = new Map<String, Contact>();
        List<Entitlement> updateEntitlement = new List<Entitlement>();
        String unMatchedParentAccId=CadenceSSOConfiguration__c.getValues('UNMATCHEDACCOUNTID').Value__c;
        for(Contact con : conList){
            okatIdConMap.put(con.Okta_Id__c,con);
        }
        for(Entitlement ent : newEntitlementList){
           if((ent.AccountId != okatIdConMap.get(ent.User_Okta_Id__c).AccountId || 
               ent.Parent_Account__c != okatIdConMap.get(ent.User_Okta_Id__c).Parent_Account__c) 
              && okatIdConMap.get(ent.User_Okta_Id__c).Parent_Account__c != unMatchedParentAccId) {
              
                ent.Parent_Account__c = okatIdConMap.get(ent.User_Okta_Id__c).Parent_Account__c;
                ent.AccountId = okatIdConMap.get(ent.User_Okta_Id__c).AccountId;
                updateEntitlement.add(ent);
                System.debug('ent'+ent);
           }
        }
        
        if(updateEntitlement.size() > 0){
            EntitlementTriggerHandler_AC.isByPassEntitlementTrigger = true;
            String failedReport ='';
            try{
                Database.SaveResult[] results = Database.update(updateEntitlement,false);   
                String errorMessage = '';
                for(Integer i=0;i<results.size();i++){
                    String failedErrors='';
                    if (!results.get(i).isSuccess()){
                        failedErrors+= 'Failed to Update Entitlement Id: '+updateEntitlement[i].Id + ' : ';
                        failedErrors+= 'Entitlement Name:'+updateEntitlement[i].Name + '-->';
                        for(Database.Error theError: results.get(i).getErrors()){  
                            errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                            failedErrors+= (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                            failedErrors += ',';
                        }
                        failedErrors = failedErrors.removeEnd(',');
                    } 
                    if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                    }
                }
                if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null))
                {
                    ECommEntitlementServiceUtility.createException('updateEntitlemntAccWithConAcc', 'Update ECommLicense Account with Contact Account', errorMessage, failedReport);
                }       
            } catch(Exception ex) {
                AsyncExceptionUtil.addtoErrorLog(updateEntitlement, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'updateEntitlemntAccWithConAcc', 'Create Task for SSG to update LOS to ECommLicense');
            } 
            EntitlementTriggerHandler_AC.isByPassEntitlementTrigger = false;  
        }

    }
    
    /**
     * Method to create a task to SSG on COS auto registration similar to self-registration.
     */
    public static void createTaskOnCOSRegistration(List<Contact> conList, Map<String,String> eComKeyUsrIdMap){
        List<Task> cosTaskList = new list<Task>();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.emailHeader.triggerUserEmail = false;   
        String subject = 'Attn: SSG/CRC - COS Account Created';
        String activityType =  'COS Contact Creation';   
		CadenceSSOConfiguration__c cadIntUsrId = CadenceSSOConfiguration__c.getValues('CADENCEINTUSERID');
		for(contact con : conList)
		{
		    Task t = createTaskRecord(con, subject, activityType, cadIntUsrId.Value__c, eComKeyUsrIdMap.get(con.Okta_Id__c));
            cosTaskList.add(t);
     	}
        System.debug('task'+cosTaskList);    
		TaskTriggerHandler_AC.isPopulateSubmitterInfo = false;
        if(cosTaskList.size() > 0){
            String failedReport ='';
            try{
                Database.SaveResult[] results = Database.insert(cosTaskList, dmo);   
                String errorMessage = '';
                for(Integer i=0;i<results.size();i++){
                    String failedErrors='';
                    if (!results.get(i).isSuccess()){
                        failedErrors+= 'Failed to create task: '+cosTaskList[i].Description + ' : ';
                        failedErrors+= 'Activity Type:'+cosTaskList[i].Activity_Type__c + '-->';
                        for(Database.Error theError: results.get(i).getErrors()){  
                            errorMessage += (theError.getMessage()!=null?theError.getMessage():'');
                            failedErrors+= (theError.getFields()!=null?string.valueOf(theError.getFields()):'');
                            failedErrors += ',';
                        }
                        failedErrors = failedErrors.removeEnd(',');
                    } 
                    if(failedErrors != ''){
                        failedReport += failedErrors + '\n';    
                    }
                }
                if((errorMessage !='' && errorMessage !=null) || (failedReport != '' && failedReport != null)){
                        ECommEntitlementServiceUtility.createException('createTaskOnCOSRegistration', 'Create Task for SSG on new COS Registration', errorMessage, failedReport);
                }       
            } catch(Exception ex) {
                AsyncExceptionUtil.addtoErrorLog(cosTaskList, ex, 'ECommToCOSAutoReg', 'ECommEntitlementService', 'createTaskOnCOSRegistration', 'Create Task for SSG on new COS Registration');
            }
        }    
		TaskTriggerHandler_AC.isPopulateSubmitterInfo = true;
    }

    /**
     * Method to create the Support Ticket for the SAAS Entitlement for which the Okta ID will couldn't be found.
     */
    public static void createSuprtTcktNonPrcssdRcrd(Map<Id, Contact> eComContact, Map<String,String> eComKeyUsrIdMap) {
        Map<String,Contact> oktaIdConMap = new Map<String,Contact>();
        String unProcessedRecord ='';
        if(eComContact.size() > 0) {
            for(Contact con : eComContact.values()){
                oktaIdConMap.put(con.Okta_Id__c,con);
            }    
            for(String oktaId : eComKeyUsrIdMap.keySet()){
                if(oktaIdConMap.get(oktaId) == null){
                    unProcessedRecord += eComKeyUsrIdMap.get(oktaId);
                }
            }
        } else {
            for(String lockingId : eComKeyUsrIdMap.values()){
                unProcessedRecord += lockingId +', '; 
            }
        }
        if(unProcessedRecord != null && unProcessedRecord != ''){
            ECommEntitlementServiceUtility.createException('eComAutoRegstrtnEntAssctn', 'Unprocessed Entitlement', 'Not processed because Okta Id did not find', 'Failed Locking Id : '+ unprocessedRecord.removeEnd(','));  
        }  
    }

    /**
     * A uitility method to pupolated the field for Community record creation.
     */
    public static User createCommunityRecord(Contact conu){
        CadenceSSOConfiguration__c cosuserprofid = CadenceSSOConfiguration__c.getValues('COSUSERPROFILEID');
        User u = new User ();
        TimeZone tz = UserInfo.getTimeZone();  
        string fStr='';
        string lStr='';
        if(conu.firstname.length() ==1 || conu.firstname.length() ==2)fStr = conu.firstname;
        if(conu.firstname.length() >=3)fStr = conu.firstname.subString(0,3);
        if(conu.Lastname.length() ==1 || conu.Lastname.length() ==2)lStr= conu.Lastname;                            
        if(conu.Lastname.length() >=3)lStr = conu.Lastname.subString(0,3);
        u.firstname = conu.firstname;
        u.lastname = conu.lastname;
        u.Profileid = cosuserprofid.Value__c;
        u.username = conu.Email;
        u.Email = conu.Email;
        u.Fax = conu.Fax;
        u.Phone = conu.Phone;
        u.MobilePhone = conu.Cellular_Phone__c;
        u.Extension = conu.Extension__c;
        u.Middle_Name__c = conu.Middle_Name__c;
        u.Address_1__c = conu.Street__c;
        u.CommunityNickname = conu.Contact_Number__c;
        u.IsActive = true;
        u.Employment_Status__c = 'Unavailable';
        u.Employee_Type__c = '';
        u.Alias=fStr+lStr;
        u.TimeZoneSidKey=tz.getID();
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.UserPermissionsMobileUser = false;
        u.contactId=conu.Id;
        u.FederationIdentifier= conu.Email;
        u.Login__c = conu.Email;

        return u;

    }

    /**
     * A utility methos to populated the fields of task creation.
     */
    public static Task createTaskRecord(Contact con, String subject, String activityType, Id ownerId, String eCommKey){
        RecordType rqt = new RecordType();
        try{
            rqt = [SELECT id, Name FROM RecordType WHERE Name = 'SSG' AND SobjectType = 'Task'];
            }catch(Exception ex){
                System.debug('Task record retrieval Exception: '+ ex + '\n Line number: ' + ex.getLineNumber() + ' \n Stack trace: ' + ex.getStackTraceString());
            }
            Task t = new Task();
            t.WhoId = con.id;
            t.OwnerId = ownerId;
            t.ActivityDate = Date.Today().addDays(7);
            t.Subject = subject;
            t.Activity_Type__c = activityType;
            t.Status = 'Not Started';
            t.Description = populateDescription(con, eCommKey, false);
            t.Submitter_Type__c = 'Customer';
            t.RecordTypeId = rqt.id;
        return t;

    }

    /**
     * A utility method to populate Email/Task description
     */
    public static String populateDescription(Contact con, String eCommKey, boolean isEmail){
        String Description= '';
        Description = 'Email: ' + con.Email+ (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Login Name: ' + con.Login_Name__c + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Parent Account: ' + con.Parent_Account__r.Name + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'First Name: ' + con.FirstName + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Last Name: ' + con.LastName + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Address 1: ' + (con.Street__c == null? '' : con.Street__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'City: ' + (con.City__c == null ? '' : con.City__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Country: ' + (con.Country__r.name == null ? '' : con.Country__r.name) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'State/Region: ' + (con.State_Region__r.name == null ? '' : con.State_Region__r.name) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Postal Code: ' + (con.Postal_Code__c == null ? '' : con.Postal_Code__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Phone: ' + (con.phone == null ? '' : con.phone) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Extension: ' + (con.Extension__c == null?'':con.Extension__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Job Title: ' + (con.Job_Title__c == null?'':con.Job_Title__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'COS ID: ' + con.Email + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Okta Id: ' + con.Okta_Id__c+ (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Host Id: ' + (con.Host_ID__c == null?'':con.Host_ID__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'Reference Key: ' + (con.Reference_Key__c == null?'':con.Reference_Key__r.name) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'LMS Key: ' + (con.LMS_Key__c == null?'':con.LMS_Key__c) + (isEmail == true? '<br/>':'\r\n');
        Description = Description+ 'LMS Active: ' + con.LMS_Active__c + (isEmail == true? '<br/>':'\r\n');
		Description = Description+ 'eCommerce Key: ' + eCommKey + (isEmail == true? '<br/><br/>':'\r\n');
        return Description;
    }

}