/**
***    Created By: Hemant Patel
***    Date:       [12/12/2013]
***    Use:        Will Store Common Helper Methods
**/


public with sharing class APTPSHelper {
    
    
    /*
    Public Static Constants which will be used across application
    */
    
    public static string PRODUCT_TYPE_SOFTWARE = 'Software';
    public static string PRODUCT_TYPE_HARDWARE = 'Hardware';
    public static string PRODUCT_TYPE_DIP = 'Design IP';
    public static string PRODUCT_SUB_TYPE_TK = 'Temp Key';
    public static Map<String,String> countryAddressMap;
    public static   Map<String,String> regionAddressMap;
    public static Map<String,String> countryRegionMapping;
    private static Map<string,string> CLLA_TK_CONVERSION_MAPPING;
    public static boolean bypassNDARUNDAAuthTrigger = false;
    // SFDC-12564 - Abhishek Pareek - START
    //Method to check if the user to SalesforceBasicProfile or the Force.com User License, from Custom Metadata - UserProvision_Configs__mdt
    public static boolean foundMatchingLicenseOrProfile(string name, string type)
    {
		List<UserProvision_Config__mdt> lic = [SELECT Id__c, Name__c FROM UserProvision_Config__mdt where SFDC_Object_Name__c=:type and Name__c=:name];
		
		if (lic.size() > 0)
			return true;
		else
			return false;
    }
    // SFDC-12564 - Abhishek Pareek - END    
        
    public static Map<string,string> RetriveCLLATKConversionMapping() {
        if(CLLA_TK_CONVERSION_MAPPING == null){
            CLLA_TK_CONVERSION_MAPPING = new Map<string,string>();
            
            CLLA_TK_CONVERSION_MAPPING.put('Demo','Demo');
            CLLA_TK_CONVERSION_MAPPING.put('Evaluation','Evaluation');
            CLLA_TK_CONVERSION_MAPPING.put('Customer Support','Customer Support');
            CLLA_TK_CONVERSION_MAPPING.put('Training','Training');
            CLLA_TK_CONVERSION_MAPPING.put('Other','');
            CLLA_TK_CONVERSION_MAPPING.put('PCR','');
            CLLA_TK_CONVERSION_MAPPING.put('Quality','');
            CLLA_TK_CONVERSION_MAPPING.put('Service','');
            CLLA_TK_CONVERSION_MAPPING.put('VCAD','');
            CLLA_TK_CONVERSION_MAPPING.put('Contract Defined','');
            CLLA_TK_CONVERSION_MAPPING.put('Technology Migration','');
            CLLA_TK_CONVERSION_MAPPING.put('Technology Workaround','');
            CLLA_TK_CONVERSION_MAPPING.put('Repackaging Workaround','');
            CLLA_TK_CONVERSION_MAPPING.put('Pre-Sales Proliferation','');
            
        }
        return CLLA_TK_CONVERSION_MAPPING;
    }
    
    /**
    ***    Final Email Regex String
    **/
    private static final String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
    private static final String ValidHostIDRegex = '[A-Za-z0-9]*';
    
    
    
    /**
    ***    Use:        This Method will validate email address
    ***    Parameter:  Email(s) Multiple email seprate by ','
    **/
    public static boolean IsValidEmails(string Emails){
        boolean isValid = true;
        //Emails = Emails.replace(',', ';');
        Pattern emailPattern = Pattern.compile(emailRegex);
        if(Emails.contains(',')){
            for(string email: Emails.split(',')){
                 email = email.trim();
                 Matcher MyMatcher = emailPattern.matcher(email);
                 if(!MyMatcher.matches()){
                    isValid=false;
                    break;
                }
            }
        }
        else{
            Matcher MyMatcher = emailPattern.matcher(Emails);
            if(!MyMatcher.matches()){
                isValid=false;
            }
        }
        
        return isValid;
        
    }
    
    /**
    ***    Use:        This Method will validate Host IDs
    ***    Parameter:  Email(s) Multiple email seprate by ','
    **/
    public static boolean IsValidHostIDs(string HostIDS){
        boolean isValid = true;
        //Emails = Emails.replace(',', ';');
        Pattern stringPattern = Pattern.compile(ValidHostIDRegex);
        if(HostIDS.contains(',')){
            for(string host: HostIDS.split(',')){
                host = host.trim();
                 Matcher MyMatcher = stringPattern.matcher(host);
                 if(!MyMatcher.matches()){
                    isValid=false;
                    break;
                }
            }
        }
        else{
            Matcher MyMatcher = stringPattern.matcher(HostIDS);
            if(!MyMatcher.matches()){
                isValid=false;
            }
        }
        
        return isValid;
        
    }
    
    
     /**
    ***    Use:        Retrive All Fields By Comma Seprate
    ***    Parameter:  strObject - Object Name
    **/
    public static string getfieldList(string strObject) {
     
         if(strObject != null && strObject != ''){
         List<SelectOption> ChildObjects = new List<SelectOption>();
         Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
         Schema.SObjectType R = gd.get(strObject);
         string returnstring = '';
         Map<String, Schema.SobjectField> fmap = R.getDescribe().fields.getMap();
         for(Schema.SobjectField sd: fmap.values())  {
                if(returnstring == ''){
                    returnstring = string.valueOf(sd);
                }
                else
                returnstring += ',' + string.valueOf(sd);
         }
             //ChildObjects.add(new SelectOption(string.valueOf(sd),string.valueOf(sd)));
         return returnstring;
         }    
         else return '';
    }

    public static string getCLLAValidation(string validationKey)
    {
        CLLA_Validations__c validationMsgForKey = CLLA_Validations__c.getValues(validationKey);
        string validationMsg = null;
        if(validationMsgForKey != null)
            validationMsg = validationMsgForKey.Message__c;
        return validationMsg;
    }

    public static String getApttusErrorMessage(String key)
    {
        CLLA_Settings__c validationMsgForKey = CLLA_Settings__c.getValues(key);
        String validationMsg = '';
        if(validationMsgForKey != null)
            validationMsg = validationMsgForKey.Message__c;
        return validationMsg;
    }

    public static string getNDASettingValue(string key)
    {
        NDA_Settings__c ndaSetting = NDA_Settings__c.getValues(key);
        string settingValue = '';
        if(ndaSetting != null)
            settingValue = ndaSetting.Message__c;
        return settingValue;
    }
    
    public static Date getETAAEndDate()
    {
        Date_Configuration__c dateConfig = Date_Configuration__c.getValues('ARM ETAA End Date');
        Date dateValue = Date.newInstance(2014,9,29);
        if(dateConfig != null)
            dateValue = dateConfig.Date_Value__c;
        return dateValue;
    }
    
    public static Date getSNPSEndDate()
    {
        Date_Configuration__c dateConfig = Date_Configuration__c.getValues('SNPS End Date');
        Date dateValue = Date.newInstance(2014,9,29);
        if(dateConfig != null)
            dateValue = dateConfig.Date_Value__c;
        return dateValue;
    }
    
    public static string getQueryForProductSelection(string key)
    {
        Agreement_Product_Selection_Query__c productSelectionQuery = Agreement_Product_Selection_Query__c.getValues(key);
        string consolidatedQuery = '';
        if(productSelectionQuery != null) {
            consolidatedQuery = (productSelectionQuery.Query_Part_I__c == null ? '' : productSelectionQuery.Query_Part_I__c);
            consolidatedQuery = consolidatedQuery + ' ' + (productSelectionQuery.Query_Part_II__c == null ? '' : productSelectionQuery.Query_Part_II__c);
            consolidatedQuery = consolidatedQuery + ' ' + (productSelectionQuery.Query_Part_III__c == null ? '' : productSelectionQuery.Query_Part_III__c);
            consolidatedQuery = consolidatedQuery + ' ' + (productSelectionQuery.Query_Part_IV__c == null ? '' : productSelectionQuery.Query_Part_IV__c);
        }
        return consolidatedQuery;
    }
    
    //ASR 640257 start    
    public static boolean isApttusPermissionInsufficient(id userId, Set<String> sufficientProfiles, Set<String> validApttusProfiles, Set<String> requiredPermissionSets,Set<String> alternativePermissionSets, Set<String> requiredEmployeeGroups, Set<String> alternativeEmployeeGroups)
    {
        if(sufficientProfiles.size() == 0) return false;
        
        List<User> employeePermissions = [Select Profile.Name, (Select PermissionSet.Name From PermissionSetAssignments 
                              WHERE PermissionSet.Name IN :requiredPermissionSets 
                              OR PermissionSet.Name IN :alternativePermissionSets) 
                              From User u WHERE id = :userId];
                              
        boolean employeePermissionsNotSufficient = false;
        if(employeePermissions.size() > 0 )
        {
            if(sufficientProfiles.contains('*') || sufficientProfiles.contains(employeePermissions[0].Profile.Name)) return false;
            List<PermissionSetAssignment> permissionSet = employeePermissions[0].PermissionSetAssignments;
    
            boolean employeeInAlternativePS = false;
            //User should have a valid profile or must be assigned one of the alternative permission sets
            if(!validApttusProfiles.contains(employeePermissions[0].Profile.Name))
            {
                //if profile is not valid, then employee must have one of the alterative permission sets
                //alternativePermissionSet = Apttus Requestor User
                if(alternativePermissionSets.size() > 0 && permissionSet.size()> 0)
                {       
                    for(PermissionSetAssignment ps : permissionSet)
                    {
                        if(alternativePermissionSets.contains(ps.PermissionSet.Name))
                            employeeInAlternativePS = true; 
                    }
                }
                if(!employeeInAlternativePS)
                    employeePermissionsNotSufficient = true;    
            }
            //If profile is valid or (profile was invalid but employee was assigned any alternative permission set)
            //then check if the employee has required permission sets and groups also
            if(validApttusProfiles.contains(employeePermissions[0].Profile.Name) 
               || !employeePermissionsNotSufficient)
            {
                //If profile is valid and no alternative permission set is assigned, one of the required permission sets should also be assigned
                //requiredPermissionSet = Apttus NDA Requestor Users/Apttus NDA Approver Users
                if(!employeeInAlternativePS && requiredPermissionSets.size() > 0 && permissionSet.size() == 0)
                    employeePermissionsNotSufficient = true;
                    
                //Also, if profile and permission set are valid, user should be a member of all required groups or one of
                //the alternative groups
                List<Group> employeeGroups = [Select g.DeveloperName, (Select GroupId, UserOrGroupId From GroupMembers where UserOrGroupId = :userId) From Group g
                WHERE DeveloperName IN :requiredEmployeeGroups OR DeveloperName IN :alternativeEmployeeGroups ];
                
                Integer employeeInRequiredGroupCount = 0;
                boolean employeeInAlternativeGroup = false;
                for(Group empGroup : employeeGroups)
                {
                    List<GroupMember> groupMember = empGroup.GroupMembers;
    
                    if(requiredEmployeeGroups.contains(empGroup.DeveloperName) && groupMember.size() > 0)
                        employeeInRequiredGroupCount++;
                    else if(alternativeEmployeeGroups.contains(empGroup.DeveloperName) && groupMember.size() > 0)
                        employeeInAlternativeGroup = true;  
                }
                //Either employee should be member of all required groups or one of the alternative groups
                if(!((requiredEmployeeGroups.size() > 0 && employeeInRequiredGroupCount == requiredEmployeeGroups.size()) 
                    || employeeInAlternativeGroup))
                    employeePermissionsNotSufficient = true;
            }
        }
        return employeePermissionsNotSufficient;
    }
    
    public static Set<String> createSetFromString(String csvString)
    {
        if(csvString == null)
            return new Set<String>();
        List<String> components = csvString.split(',');
        Set<String> result = new Set<String>();
        for(String comp: components)
        {
            if(comp != null && comp != '')
                result.add(comp);
        }
        return result;
    }
    //ASR 640257 end 
    
    public static void populateMaps(){
        Map<String, Apttus_Region_Address_preferences__c> mcs = Apttus_Region_Address_preferences__c.getAll();
        countryAddressMap=new Map<String,String>();
        regionAddressMap=new Map<String,String>();
        for( Apttus_Region_Address_preferences__c arap: mcs.values()){
            if(arap.Region__c!=null){
                regionAddressMap.put(arap.Region__c.toUpperCase(),arap.Address_Preferences__c.toUpperCase());
            }else if(arap.Country__c!=null){
                countryAddressMap.put(arap.Country__c.toUpperCase(),arap.Address_Preferences__c.toUpperCase());
        }
        }
        countryRegionMapping=new Map<String,String>();
        for( Apttus_Country_region_mapping__c arap: Apttus_Country_region_mapping__c.getAll().values()){
                countryRegionMapping.put(arap.name.toUpperCase(),arap.Region__c.toUpperCase());
        }
    }
    public static String fetchAccountAddressFromAccountSite(Account_Sites__c acs){
        String country='Default';
        String  address1;
        String address2;
        String address3;
        String address4;
        String city;
        String county;
        String state;
        String zip;
        if(acs.Account__r.Apttus_Country__c!=null)
            country=acs.Account__r.Apttus_Country__r.name;
        else if(acs.Country__c!=null)
            country=acs.Country__c; 
    
        if(acs.Account__r.Apttus_Address__c!=null){
                    address1 = acs.Account__r.Apttus_Address__c;    
        }else if(acs.Address__c!=null)
                     address1 = acs.Address__c;
        
        if(acs.Account__r.Apttus_Address_2__c!=null)
                 address2 = acs.Account__r.Apttus_Address_2__c;            
        else if(acs.Account__r.Address_2__c!=null)
                address2 =acs.Account__r.Address_2__c;
        
        if(acs.Account__r.Apttus_Address_3__c!=null)
                     address3 = acs.Account__r.Apttus_Address_3__c;
        else if(acs.Account__r.Address_3__c!=null)
                     address3 =acs.Account__r.Address_3__c;
            
        if(acs.Account__r.Apttus_Address_4__c!=null)
                    address4 = acs.Account__r.Apttus_Address_4__c;
        else if(acs.Account__r.Address_4__c!=null)
                    address4 = acs.Account__r.Address_4__c;
                
        if(acs.Account__r.Apttus_City__c!=null)
                   city=acs.Account__r.Apttus_City__c;
         else if(acs.City__c!=null)
                    city=acs.City__c;
                
        if(acs.Account__r.Apttus_County__c!=null)
                    county=acs.Account__r.Apttus_County__c;
        else if(acs.Account__r.County__c!=null)
                    county=acs.Account__r.County__c;
                
         if(acs.Account__r.Apttus_State_Region__c!=null)
                    state=acs.Account__r.Apttus_State_Region__r.name;
         else if(acs.State__c!=null)
                    state=acs.State__c;
            
         if(acs.Account__r.Apttus_Postal_Code__c!=null)
                zip=acs.Account__r.Apttus_Postal_Code__c;  
         else if(acs.Zip_Code__c!=null)
                zip=acs.Zip_Code__c;
       String countryUppercase= country.toUpperCase();
       System.debug('country::'+country);
       String addressPreferences='';
       system.debug('regionAddressMap::'+regionAddressMap);
        system.debug('countryAddressMap::'+countryAddressMap);
        system.debug('countryRegionMapping::'+countryRegionMapping);
       if(countryAddressMap!=null && countryAddressMap.get(countryUppercase)!=null){
            addressPreferences=countryAddressMap.get(countryUppercase);
       }else{
            String region;
                region=countryRegionMapping.get(countryUppercase);
            if(region==null){
                region='NORTH AMERICA';
            }
             System.debug('region::'+region);
            if(regionAddressMap.get(region)!=null)
                addressPreferences=regionAddressMap.get(region);
            else{
                region='NORTH AMERICA';
                addressPreferences=regionAddressMap.get(region);
                
            }
            
       }
       // Jitendra, just adding null pointer check
       List<String> orderOfAddress;
       if( String.isNotBlank(addressPreferences)){
           orderOfAddress=addressPreferences.split(';');
       }
        
        System.debug('orderOfAddress::'+addressPreferences);
        String address='';
        boolean firstime=true;
        boolean lastTimeStringAdded=false;
        If(orderOfAddress != null){
            for(String s:orderOfAddress){
                String currentAddressComponent; 
                if(!firstime && lastTimeStringAdded){
                    address+=', ';
                    lastTimeStringAdded=false;
                }else{
                    firstime=false;
                }
                if(s.equalsIgnoreCase('Street')){
                    currentAddressComponent=address1;
                }else if(s.equalsIgnoreCase('Division')){
                    currentAddressComponent=address2;
                }else if(s.equalsIgnoreCase('Address 3')){
                    currentAddressComponent=address3;
                }else if(s.equalsIgnoreCase('Address 4')){
                    currentAddressComponent=address4;
                }else if(s.equalsIgnoreCase('City')){
                    currentAddressComponent=city;
                }else if(s.equalsIgnoreCase('Postal Code')){
                    currentAddressComponent=zip;
                }else if(s.equalsIgnoreCase('State/Region')){
                    currentAddressComponent=state;
                }else if(s.equalsIgnoreCase('Country')){
                    currentAddressComponent=country;
                }else if(s.equalsIgnoreCase('County/Sub Locality')){
                    currentAddressComponent=county;
                }
                
                if(currentAddressComponent!=null){
                    address+=currentAddressComponent;
                    lastTimeStringAdded=true;
                }
            }
        }
        system.debug('address::'+address);
        return address;
    }
}