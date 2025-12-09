/**
 * Service for translating Knowledge articles using simpleT (Google Translate)
 * Created by nikola on 10.09.2025
 * Refactored for improved readability and performance
 *
 * ==================== CONFIGURATION GUIDE ====================
 * This service automatically translates Knowledge articles to different languages.
 *
 * TO CUSTOMIZE WITH YOUR OWN FIELDS:
 * Edit the getTranslatableFields() method (line ~202)
 * Add/remove field API names in the returned List
 *
 * IMPORTANT: After editing getTranslatableFields(), you MUST also update:
 * - queryTargetArticles() method (line ~48) - add fields to SELECT clause
 * - fetchMasterRecords() method (line ~64) - add fields to SELECT clause
 * =========================================================
 */
public class KnowledgeTranslationService {
    private static final String TRANSLATION_ENGINE = 'ST Google Translate Default';
    private static List<String> picklistFieldsCache;

    @Future(Callout=true)
    public static void translateKnowledgeArticles(Set<Id> knowledgeIds) {
        if(knowledgeIds == null || knowledgeIds.isEmpty()) {
            return;
        }

        try {
            List<Knowledge__kav> targetArticles = queryTargetArticles(knowledgeIds);

            if(targetArticles.isEmpty()) {
                return;
            }

            Map<Id, Knowledge__kav> masterRecordMap = fetchMasterRecords(targetArticles);
            TranslationPackage translationPkg = prepareTranslations(targetArticles, masterRecordMap);

            if(translationPkg.isEmpty()) {
                return;
            }

            List<simpleT.ST_TranslationWrapper> results = simpleT.ST_TranslateInvocable.stTranslate(
                translationPkg.translationWrappers
            );

            updateKnowledgeArticles(results, translationPkg, masterRecordMap, targetArticles);

        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'KnowledgeTranslationService Error: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
    }

    // ==================== Query Methods ====================

    /**
     * Query target knowledge articles that need translation
     *
     * CUSTOMIZATION:
     * Add your custom translatable fields to the SELECT clause below
     * Example: SELECT Id, KnowledgeArticleId, Language, Summary, Title, Question__c, Answer__c, YourField__c
     *
     * IMPORTANT: Make sure field names match exactly what you added in getTranslatableFields()
     */
    private static List<Knowledge__kav> queryTargetArticles(Set<Id> knowledgeIds) {
        return [
            SELECT Id, KnowledgeArticleId, Language, Summary, Title, Question__c
            FROM Knowledge__kav
            WHERE Id IN :knowledgeIds
        ];
    }

    /**
     * Fetch master language records for translation source content
     *
     * CUSTOMIZATION:
     * Add your custom translatable fields to the SELECT clause below
     * Example: SELECT Id, KnowledgeArticleId, Language, IsMasterLanguage, Summary, Title, Answer__c, Question__c, YourField__c
     *
     * IMPORTANT:
     * 1. Field names must match getTranslatableFields()
     * 2. This method retrieves the SOURCE language (master) record
     * 3. The translations will be pulled from these fields
     */
    private static Map<Id, Knowledge__kav> fetchMasterRecords(List<Knowledge__kav> targetArticles) {
        Set<Id> articleIds = new Set<Id>();
        for(Knowledge__kav article : targetArticles) {
            articleIds.add(article.KnowledgeArticleId);
        }

        List<Knowledge__kav> masterRecords = [
            SELECT Id, KnowledgeArticleId, Language, IsMasterLanguage, Summary, Title, Question__c
            FROM Knowledge__kav
            WHERE KnowledgeArticleId IN :articleIds AND IsMasterLanguage = true
        ];

        Map<Id, Knowledge__kav> masterRecordMap = new Map<Id, Knowledge__kav>();
        for(Knowledge__kav master : masterRecords) {
            masterRecordMap.put(master.KnowledgeArticleId, master);
        }

        return masterRecordMap;
    }

    // ==================== Translation Preparation ====================

    /**
     * Prepare translation wrappers and context for API call
     */
    private static TranslationPackage prepareTranslations(
        List<Knowledge__kav> targetArticles,
        Map<Id, Knowledge__kav> masterRecordMap
    ) {
        TranslationPackage pkg = new TranslationPackage();
        List<String> fieldNames = getTranslatableFields();

        for(Knowledge__kav targetArticle : targetArticles) {
            Knowledge__kav masterRecord = masterRecordMap.get(targetArticle.KnowledgeArticleId);

            if(masterRecord == null) {
                continue;
            }

            for(Integer fieldIndex = 0; fieldIndex < fieldNames.size(); fieldIndex++) {
                String fieldName = fieldNames[fieldIndex];
                String fieldValue = (String) masterRecord.get(fieldName);

                if(String.isBlank(fieldValue)) {
                    continue;
                }

                simpleT.ST_TranslationWrapper wrapper = createTranslationWrapper(
                    fieldValue,
                    masterRecord.Language,
                    targetArticle.Language
                );

                pkg.add(wrapper, targetArticle.Id, fieldIndex);
            }
        }

        return pkg;
    }

    /**
     * Create a translation wrapper for simpleT API
     */
    private static simpleT.ST_TranslationWrapper createTranslationWrapper(
        String textToTranslate,
        String sourceLanguage,
        String targetLanguage
    ) {
        simpleT.ST_TranslationWrapper wrapper = new simpleT.ST_TranslationWrapper();
        wrapper.targetLanguages = new List<String>{ targetLanguage };
        wrapper.sourceLanguage = sourceLanguage;
        wrapper.engine = TRANSLATION_ENGINE;
        wrapper.salesforceComponent = true;
        wrapper.text = textToTranslate;
        return wrapper;
    }

    // ==================== Update Methods ====================

    /**
     * Update knowledge articles with translated content
     */
    private static void updateKnowledgeArticles(
        List<simpleT.ST_TranslationWrapper> results,
        TranslationPackage translationPkg,
        Map<Id, Knowledge__kav> masterRecordMap,
        List<Knowledge__kav> targetArticles
    ) {
        Map<Id, Knowledge__kav> recordsToUpdate = new Map<Id, Knowledge__kav>();
        List<String> fieldNames = getTranslatableFields();

        for(Integer i = 0; i < results.size(); i++) {
            simpleT.ST_TranslationWrapper result = results[i];

            if(result.translations == null || result.translations.isEmpty()) {
                continue;
            }

            TranslationRecord transRecord = translationPkg.records[i];
            String translatedText = result.translations[0].translation;

            Knowledge__kav articleToUpdate = recordsToUpdate.get(transRecord.targetArticleId);
            if(articleToUpdate == null) {
                articleToUpdate = new Knowledge__kav(Id = transRecord.targetArticleId);
                recordsToUpdate.put(transRecord.targetArticleId, articleToUpdate);
            }

            String fieldName = fieldNames[transRecord.fieldIndex];
            articleToUpdate.put(fieldName, translatedText);
        }

        // Copy picklist values from master records
        List<String> picklistFields = getCachedPicklistFields();
        for(Knowledge__kav targetArticle : targetArticles) {
            if(!recordsToUpdate.containsKey(targetArticle.Id)) {
                recordsToUpdate.put(targetArticle.Id, new Knowledge__kav(Id = targetArticle.Id));
            }

            Knowledge__kav masterRecord = masterRecordMap.get(targetArticle.KnowledgeArticleId);
            if(masterRecord != null) {
                for(String picklistField : picklistFields) {
                    Object picklistValue = masterRecord.get(picklistField);
                    if(picklistValue != null) {
                        recordsToUpdate.get(targetArticle.Id).put(picklistField, picklistValue);
                    }
                }
            }
        }

        // Perform update
        if(!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate.values();
            } catch(Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error updating knowledge articles: ' + e.getMessage());
            }
        }
    }

    // ==================== Field Configuration ====================

    /**
     * Get list of fields that should be translated
     *
     * CUSTOMIZATION:
     * 1. Add your custom field API names to the list below
     * 2. Field names are case-sensitive (e.g., 'Question__c' not 'question__c')
     * 3. Use API names, not labels
     * 4. Supported field types: Text, Text Area, Long Text Area, Rich Text Area
     *
     * EXAMPLE - Adding 3 new fields:
     * return new List<String>{
     *     'Summary',          // Standard field
     *     'Title',            // Standard field
     *     'Question__c',      // Custom field
     *     'Answer__c',        // Your custom field - ADD HERE
     *     'Description__c',   // Your custom field - ADD HERE
     *     'Keywords__c',      // Your custom field - ADD HERE
     * };
     *
     * CRITICAL: After adding fields here, you MUST also update:
     *     1. queryTargetArticles() method (line ~71) - add to SELECT clause
     *     2. fetchMasterRecords() method (line ~91) - add to SELECT clause
     */
    private static List<String> getTranslatableFields() {
        return new List<String>{
            'Summary',
            'Title',
            'Question__c'
        };
    }

    /**
     * Get cached list of picklist fields (avoid repeated schema calls)
     */
    private static List<String> getCachedPicklistFields() {
        if(picklistFieldsCache != null) {
            return picklistFieldsCache;
        }

        picklistFieldsCache = new List<String>();
        Schema.SObjectType objType = Knowledge__kav.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for(String fieldName : getTranslatableFields()) {
            if(fieldMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
                    picklistFieldsCache.add(fieldName);
                }
            }
        }

        return picklistFieldsCache;
    }

    // ==================== Helper Classes ====================

    /**
     * Wrapper class for managing translation data and context
     */
    private class TranslationPackage {
        public List<simpleT.ST_TranslationWrapper> translationWrappers;
        public List<TranslationRecord> records;

        public TranslationPackage() {
            this.translationWrappers = new List<simpleT.ST_TranslationWrapper>();
            this.records = new List<TranslationRecord>();
        }

        public void add(simpleT.ST_TranslationWrapper wrapper, Id targetArticleId, Integer fieldIndex) {
            this.translationWrappers.add(wrapper);
            this.records.add(new TranslationRecord(targetArticleId, fieldIndex));
        }

        public Boolean isEmpty() {
            return this.translationWrappers.isEmpty();
        }
    }

    /**
     * Tracks context for each translation result
     */
    private class TranslationRecord {
        public Id targetArticleId;
        public Integer fieldIndex;

        public TranslationRecord(Id targetArticleId, Integer fieldIndex) {
            this.targetArticleId = targetArticleId;
            this.fieldIndex = fieldIndex;
        }
    }
}