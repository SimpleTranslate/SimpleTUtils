/**
 * @description Use Case Example: Async Translation Service with Queueable
 * This example demonstrates how to use the ST_TranslateInvocable service asynchronously
 * via the TranslationPollingQueueable to translate Lead descriptions from German to English.
 *
 * Scenario: When a new Lead is created with a description in German, automatically
 * translate it to English and update the Lead's Description field asynchronously.
 */
public with sharing class AsyncTranslationQueueableUseCase {

    /**
     * @description Main method that demonstrates the async translation workflow.
     * Call this method when you need to translate a Lead's description asynchronously.
     *
     * @param leadId The ID of the Lead record to translate
     * @param sourceText The text to translate (e.g., the original Lead description)
     * @param sourceLanguage The source language code (e.g., 'de' for German)
     * @param targetLanguage The target language code (e.g., 'en_GB' for English)
     *
     * Example:
     *   String leadId = '00QQH00000IuzT42AJ';
     *   String germanText = 'Guten Morgen, ich bin interessiert';
     *   translateLeadDescriptionAsync(leadId, germanText, 'de', 'en_GB');
     */
    public static void translateLeadDescriptionAsync(
        String leadId,
        String sourceText,
        String sourceLanguage,
        String targetLanguage
    ) {
        // Step 1: Create a translation wrapper to configure the translation request
        ST_TranslationWrapper translationWrapper = new ST_TranslationWrapper();

        // Set the text to translate
        translationWrapper.text = sourceText;

        // Set the source language
        translationWrapper.sourceLanguage = sourceLanguage;

        // Set target languages as a list (can translate to multiple languages at once)
        translationWrapper.targetLanguages = new List<String>{ targetLanguage };

        // Specify the translation engine to use
        translationWrapper.engine = 'ST Google Translate Default';

        // Enable async mode - this returns immediately with a job ID
        translationWrapper.is_async = true;

        // Wrap in a list (the service accepts a list of wrappers for batch processing)
        List<ST_TranslationWrapper> translationWrapperList = new List<ST_TranslationWrapper>{ translationWrapper };

        try {
            // Step 2: Call the translation service asynchronously
            // This will return immediately with a job ID instead of waiting for translation results
            List<ST_TranslationWrapper> responseList = ST_TranslateInvocable.stTranslate(translationWrapperList);

            // Step 3: Extract the job ID from the response
            // The job ID is used to poll for translation results later
            if (responseList != null && !responseList.isEmpty()) {
                String jobId = responseList[0].jobId;

                System.debug(LoggingLevel.INFO, 'Translation job queued with ID: ' + jobId + ' for Lead: ' + leadId);

                // Step 4: Enqueue the polling queueable with an initial delay of 0 attempts
                // The queueable will poll the translation status and update the Lead when complete
                // The delay parameter allows for retries if the translation isn't ready
                System.enqueueJob(new TranslationPollingQueueable(jobId, leadId, 0));

            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to initiate translation job');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error initiating async translation: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
    }
}

/**
 * USAGE EXAMPLES:
 *
 * 1. Simple translation of a single Lead:
 *    AsyncTranslationQueueableUseCase.translateLeadDescriptionAsync(
 *        '00QQH00000IuzT42AJ',
 *        'Guten Morgen, ich bin interessiert an Ihren Produkten',
 *        'de',
 *        'en_GB'
 *    );
 *
 * HOW IT WORKS:
 * 1. Create an ST_TranslationWrapper with your text and language settings
 * 2. Set is_async = true to enable async mode
 * 3. Call ST_TranslateInvocable.stTranslate() which returns immediately with a jobId
 * 4. The jobId is used to poll for translation results
 * 5. Pass the jobId and Lead ID to TranslationPollingQueueable
 * 6. The queueable automatically polls for results and updates the Lead when ready
 * 7. If the translation isn't ready, it re-enqueues itself with a 1-minute delay
 * 8. Maximum of 5 polling attempts before giving up
 */
