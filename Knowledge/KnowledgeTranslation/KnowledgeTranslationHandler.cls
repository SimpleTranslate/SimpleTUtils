/**
 * Service for translating Knowledge articles using simpleT (Google Translate)
 * Created by nikola on 10.09.2025
 * Refactored for improved readability and performance
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
     */
    private static List<Knowledge__kav> queryTargetArticles(Set<Id> knowledgeIds) {
        return [
            SELECT Id, KnowledgeArticleId, Language, Summary, Title, Question__c, Answer__c
            FROM Knowledge__kav
            WHERE Id IN :knowledgeIds
        ];
    }

    /**
     * Fetch master language records for translation source content
     */
    private static Map<Id, Knowledge__kav> fetchMasterRecords(List<Knowledge__kav> targetArticles) {
        Set<Id> articleIds = new Set<Id>();
        for(Knowledge__kav article : targetArticles) {
            articleIds.add(article.KnowledgeArticleId);
        }

        List<Knowledge__kav> masterRecords = [
            SELECT Id, KnowledgeArticleId, Language, IsMasterLanguage, Summary, Title, Answer__c, Question__c
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
     * Configure translatable fields here
     */
    private static List<String> getTranslatableFields() {
        return new List<String>{
            'Summary',
            'Title',
            'Question__c',
            'Answer__c'
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