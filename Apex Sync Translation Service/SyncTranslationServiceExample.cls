/**
 * @description Use Case Examples: Synchronous Translation Service
 * This class demonstrates how to use the ST_TranslateInvocable service synchronously
 * to translate text and get immediate results without waiting for background jobs.
 *
 * Scenario: Translate Lead descriptions, account names, or other fields instantly
 * and process the results immediately in your code flow.
 */
public with sharing class SyncTranslationServiceExample {

    /**
     * @description Translates a single text string synchronously and returns the result.
     * The translation completes immediately and returns the translated text.
     *
     * @param sourceText The text to translate
     * @param sourceLanguage The source language code (e.g., 'de' for German)
     * @param targetLanguage The target language code (e.g., 'en_GB' for English)
     * @return The translated text, or null if translation failed
     *
     * Example:
     *   String germanText = 'Guten Morgen, ich bin interessiert';
     *   String englishText = translateText(germanText, 'de', 'en_GB');
     *   System.debug('Translation: ' + englishText);  // Good morning, I am interested
     */
    public static String translateText(String sourceText, String sourceLanguage, String targetLanguage) {
        // Create a translation wrapper for the request
        ST_TranslationWrapper wrapper = new ST_TranslationWrapper();
        wrapper.text = sourceText;
        wrapper.sourceLanguage = sourceLanguage;
        wrapper.targetLanguages = new List<String>{ targetLanguage };
        wrapper.engine = 'ST Google Translate Default';
        wrapper.is_async = false;  // Key: Set to false for synchronous mode

        try {
            // Call the translation service synchronously
            // This will wait for the translation to complete before returning
            List<ST_TranslationWrapper> responseList = ST_TranslateInvocable.stTranslate(
                new List<ST_TranslationWrapper>{ wrapper }
            );

            if (responseList != null && !responseList.isEmpty()) {
                ST_TranslationWrapper response = responseList[0];

                // Check if translation was successful
                if (response.translations != null && !response.translations.isEmpty()) {
                    return response.translations[0].translation;
                }
            }

            System.debug(LoggingLevel.WARN, 'Translation returned no results');
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Synchronous translation error: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Translates a Lead's description field and returns the translated Lead record.
     * The translation happens immediately and the Lead is updated in memory.
     *
     * @param lead The Lead record to translate
     * @param sourceLanguage The source language of the description
     * @param targetLanguage The target language to translate to
     * @return The Lead record with translated Description field, or original if translation fails
     *
     * Example:
     *   Lead myLead = [SELECT Id, Description FROM Lead WHERE Id = :leadId];
     *   Lead translatedLead = translateLeadDescription(myLead, 'de', 'en_GB');
     *   // translatedLead.Description now contains the English translation
     */
    public static Lead translateLeadDescription(Lead lead, String sourceLanguage, String targetLanguage) {
        if (lead == null || String.isBlank(lead.Description)) {
            System.debug(LoggingLevel.WARN, 'Lead or description is null/blank');
            return lead;
        }

        String translatedText = translateText(lead.Description, sourceLanguage, targetLanguage);

        if (String.isNotBlank(translatedText)) {
            lead.Description = translatedText;
        }

        return lead;
    }
}

/**
 * USAGE EXAMPLES:
 *
 * 1. Simple text translation with immediate result:
 *    String germanText = 'Guten Morgen, ich bin interessiert';
 *    String englishText = SyncTranslationServiceExample.translateText(germanText, 'de', 'en_GB');
 *    System.debug('Result: ' + englishText);
 *
 * 3. Translate a single Lead description:
 *    Lead myLead = [SELECT Id, Description FROM Lead WHERE Id = :leadId];
 *    Lead translatedLead = SyncTranslationServiceExample.translateLeadDescription(myLead, 'de', 'en_GB');
 *    update translatedLead;
 *
 * HOW IT WORKS (SYNCHRONOUS):
 * 1. Create an ST_TranslationWrapper with your text and language settings
 * 2. Set is_async = false to enable synchronous mode (this is KEY!)
 * 3. Call ST_TranslateInvocable.stTranslate() which WAITS for translation to complete
 * 4. Service blocks execution until translation is finished (typically 2-5 seconds)
 * 5. Immediately returns a list of ST_TranslationWrapper with populated translations field
 * 6. Your code can process results right away without waiting for background jobs
 * 7. Perfect for immediate feedback, inline processing, and simple translations
 *
 * SYNCHRONOUS VS ASYNCHRONOUS:
 * Synchronous (this file):
 *   - Returns immediately with results
 *   - Blocks code execution while waiting (2-10 seconds typical)
 *   - No queueable jobs needed
 *   - Use when you need results right away
 *   - Perfect for Flows, Triggers, and Apex actions
 *
 * Asynchronous (AsyncTranslationQueueableUseCase):
 *   - Returns immediately with job ID
 *   - Doesn't block code execution
 *   - Polls in background via queueable
 *   - Use for large volumes or long operations
 *   - Better for batch operations
 */
