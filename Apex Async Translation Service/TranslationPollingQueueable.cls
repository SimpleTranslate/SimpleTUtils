public with sharing class TranslationPollingQueueable implements Queueable, Database.AllowsCallouts {

    private String jobId;
    private String recordId;
    private Integer pollAttempt;
    private static final Integer MAX_POLL_ATTEMPTS = 5;

    /**
     * @description Constructor to initialize the polling queueable
     * @param jobId The ID of the async translation job to poll
     * @param recordId The ID of the Lead record to update with translation results
     * @param pollAttempt The current poll attempt number
     */
    public TranslationPollingQueueable(String jobId, String recordId, Integer pollAttempt) {
        this.jobId = jobId;
        this.recordId = recordId;
        this.pollAttempt = pollAttempt;
    }

    /**
     * @description Execute method called by the Queueable framework asynchronously.
     * Polls the translation job status and updates the Lead if complete.
     * Aborts the scheduler when polling is complete or max attempts exceeded.
     * @param context The queueable context provided by Salesforce
     */
    public void execute(QueueableContext context) {
        try {
            pollAttempt++;

            System.debug(LoggingLevel.INFO, 'TranslationPollingQueueable: Polling job ' + jobId + ', attempt ' + pollAttempt);

            // Poll the translation job status
            List<String> jobIds = new List<String> {jobId};
            List<simpleT.ST_TranslationWrapper> results = simpleT.ST_PollTranslationStatusInvocable.pollTranslationStatus(jobIds);

            // Check if translation is complete
            if (results != null && !results.isEmpty()) {
                // Translation completed successfully
                System.debug(LoggingLevel.INFO, 'TranslationPollingQueueable: Job ' + jobId + ' completed successfully on attempt ' + pollAttempt);

                // Update the Lead record with translation results
                processCompletedTranslations(results);

                return;

            } else if (pollAttempt >= MAX_POLL_ATTEMPTS) {
                // Max poll attempts exceeded
                System.debug(LoggingLevel.ERROR, 'TranslationPollingQueueable: Job ' + jobId + ' exceeded max poll attempts (' + MAX_POLL_ATTEMPTS + ')');
                logTranslationError('Translation job ' + jobId + ' exceeded maximum poll attempts of ' + MAX_POLL_ATTEMPTS);

                return;
            } else {
                System.enqueueJob(new TranslationPollingQueueable(jobId, recordId, pollAttempt), 1);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TranslationPollingQueueable: Exception during polling - ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            logTranslationError(e);

            return;
        }
    }

    /**
     * @description Processes completed translation results by updating the Lead description.
     * Extracts the first translation result and updates the Lead record.
     * @param translations The completed ST_TranslationWrapper objects with populated translations field
     */
    private void processCompletedTranslations(List<simpleT.ST_TranslationWrapper> translations) {
        try {
            if (translations.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'TranslationPollingQueueable: No translations returned');
                return;
            }

            simpleT.ST_TranslationWrapper translation = translations[0];

            if (translation.translations == null || translation.translations.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'TranslationPollingQueueable: No translation results in wrapper');
                return;
            }

            // Extract the first translation result
            simpleT.ST_TranslationResponseWrapper translationResult = translation.translations[0];
            String translatedText = translationResult.translation;

            if (String.isBlank(translatedText)) {
                System.debug(LoggingLevel.WARN, 'TranslationPollingQueueable: Translated text is blank');
                return;
            }

            // Update the Lead record description with the translated text
            Lead leadToUpdate = new Lead(
                Id = recordId,
                Description = translatedText
            );

            update leadToUpdate;

            System.debug(LoggingLevel.INFO, 'TranslationPollingQueueable: Successfully updated Lead ' + recordId + ' description with translation');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TranslationPollingQueueable: Error processing translation - ' + e.getMessage());
            logTranslationError(e);
        }
    }

    /**
     * @description Logs translation errors for debugging and auditing.
     * @param errorMessage The error message to log
     */
    private void logTranslationError(String errorMessage) {
        System.debug(LoggingLevel.ERROR, 'TranslationPollingQueueable: Error logged - ' + errorMessage);
    }

    /**
     * @description Logs translation errors for debugging and auditing.
     * @param e The exception that occurred during translation processing
     */
    private void logTranslationError(Exception e) {
        System.debug(LoggingLevel.ERROR, 'TranslationPollingQueueable: Error logged - ' + e.getMessage());
    }
}