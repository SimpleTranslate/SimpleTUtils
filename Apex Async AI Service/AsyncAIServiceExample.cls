/**
 * @description Use Case Examples: Asynchronous AI Service
 * This class demonstrates how to use the ST_AIServiceInvocable service asynchronously
 * to process text with AI without blocking execution, perfect for long-running operations,
 * batch processing, and scenarios where you don't need immediate results.
 *
 * Scenario: Batch analyze hundreds of leads, process complex AI tasks in background,
 * enrich records without blocking user workflows, and retrieve results when ready.
 * Receive immediate Run ID and Thread ID to track and retrieve results later.
 */
public with sharing class AsyncAIServiceExample {

    /**
     * @description Initiates AI processing asynchronously and returns tracking IDs.
     * The AI processing happens in the background; your code continues immediately.
     * Use the returned Run ID and Thread ID to retrieve results later.
     *
     * @param userMessage The text to process or question to ask the AI
     * @param aiInstructions The AI instructions/prompt to guide the processing (e.g., '{{?SENTIMENT_ANALYSIS}}')
     * @return Map containing 'runId' and 'threadId' for tracking the async job, or null if initiation failed
     *
     * Example:
     *   String feedback = 'The product is amazing but delivery was slow';
     *   Map<String, String> jobIds = initiateAsyncAIProcessing(feedback, '{{?SENTIMENT_ANALYSIS}}');
     *   if (jobIds != null) {
     *     String runId = jobIds.get('runId');
     *     String threadId = jobIds.get('threadId');
     *     System.debug('Processing started. RunId: ' + runId);
     *   }
     */
    public static Map<String, String> initiateAsyncAIProcessing(String userMessage, String aiInstructions) {
        ST_AIInvocableWrapper wrapper = new ST_AIInvocableWrapper();
        wrapper.userMessage = userMessage;
        wrapper.aiInstructions = aiInstructions;
        wrapper.executeAsync = true;  // Key: Set to true for asynchronous mode

        try {
            List<ST_AIResponseDataWrapper> responseList = ST_AIServiceInvocable.stAiService(
                new List<ST_AIInvocableWrapper>{ wrapper }
            );

            if (responseList != null && !responseList.isEmpty()) {
                ST_AIResponseDataWrapper response = responseList[0];

                // Check if we got the tracking IDs
                if (String.isNotBlank(response.id) && String.isNotBlank(response.thread_id)) {
                    Map<String, String> jobIds = new Map<String, String>();
                    jobIds.put('runId', response.id);
                    jobIds.put('threadId', response.thread_id);
                    jobIds.put('finalResponseMessage', response.finalResponseMessage);  // Empty on async initiation
                    return jobIds;
                }
            }

            System.debug(LoggingLevel.WARN, 'AI async initiation returned no tracking IDs');
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Async AI processing initiation error: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Example 1: Batch analyze multiple Leads asynchronously
     * Use case: Enrich hundreds of leads with sentiment analysis without blocking
     * the system, then retrieve and store results when processing completes
     *
     * @param leads List of Lead records to analyze
     * @return Map of Lead ID to async job tracking info (runId, threadId)
     *
     * Example:
     *   List<Lead> newLeads = [SELECT Id, Description FROM Lead WHERE CreatedDate = TODAY LIMIT 100];
     *   Map<String, Map<String, String>> jobs = batchAnalyzeLeadSentiment(newLeads);
     *   // Continue with other work; check results later
     *   for (String leadId : jobs.keySet()) {
     *     System.debug('Lead ' + leadId + ' processing under RunId: ' + jobs.get(leadId).get('runId'));
     *   }
     */
    public static Map<String, Map<String, String>> batchAnalyzeLeadSentiment(List<Lead> leads) {
        Map<String, Map<String, String>> jobTracking = new Map<String, Map<String, String>>();

        if (leads == null || leads.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Leads list is null or empty');
            return jobTracking;
        }

        for (Lead lead : leads) {
            if (String.isBlank(lead.Description)) {
                continue;
            }

            Map<String, String> jobIds = initiateAsyncAIProcessing(
                lead.Description,
                '{{?SENTIMENT_ANALYSIS}}'
            );

            if (jobIds != null) {
                jobTracking.put(lead.Id, jobIds);
                System.debug('Initiated async sentiment analysis for Lead ' + lead.Id);
            }
        }

        System.debug('Batch async analysis initiated: ' + jobTracking.size() + ' jobs started');
        return jobTracking;
    }
}

/**
 * USAGE EXAMPLES:
 *
 * 1. Initiate async sentiment analysis and get RunId:
 *    Map<String, String> jobIds = AsyncAIServiceExample.initiateAsyncAIProcessing(
 *      lead.Description,
 *      '{{?SENTIMENT_ANALYSIS}}'
 *    );
 *    String runId = jobIds.get('runId');
 *    String threadId = jobIds.get('threadId');
 *    System.debug('Processing started with RunId: ' + runId);
 *
 * 2. Batch analyze 100+ leads without blocking:
 *    List<Lead> newLeads = [SELECT Id, Description FROM Lead WHERE CreatedDate = TODAY LIMIT 100];
 *    Map<String, Map<String, String>> jobs = AsyncAIServiceExample.batchAnalyzeLeadSentiment(newLeads);
 *    // Continue with other work immediately
 *    System.debug('Started ' + jobs.size() + ' background analysis jobs');
 *
 * HOW IT WORKS (ASYNCHRONOUS):
 * 1. Create an ST_AIInvocableWrapper with userMessage and aiInstructions
 * 2. Set executeAsync = true to enable asynchronous mode
 * 3. Call ST_AIServiceInvocable.stAiService() which returns IMMEDIATELY
 * 4. Service returns Run ID and Thread ID for tracking
 * 5. AI processing happens in background (no waiting)
 * 6. Your code continues executing immediately
 * 7. Use Run ID and Thread ID to retrieve results later (when ready)
 * 8. Perfect for batch operations and long-running processes
 *
 * SYNCHRONOUS VS ASYNCHRONOUS:
 * Synchronous (SyncAIServiceExample):
 *   - Waits for AI response before returning (3-30 seconds)
 *   - Blocks code execution
 *   - Returns finalResponseMessage immediately
 *   - Use: Single items, immediate feedback needed, Flows, Triggers
 *   - Best for: User-facing operations, quick processing
 *
 * Asynchronous (this file):
 *   - Returns immediately with Run ID and Thread ID
 *   - Doesn't block code execution
 *   - Processing happens in background
 *   - Use: Batch operations, large volumes, long-running tasks
 *   - Best for: Bulk enrichment, queue processing, scheduled jobs
 *   - Retrieve results later using Run ID
 *
 * IMPORTANT: Setting up AI Instructions (Prompts)
 * The aiInstructions parameter uses the format: '{{?PROMPTAPINAME}}'
 * You must have the prompt configured in the Simple Translate UI with the corresponding API name.
 * Common prompt patterns:
 *   - '{{?SENTIMENT_ANALYSIS}}' - Analyze sentiment of text
 *   - '{{?CASE_CLASSIFICATION}}' - Classify case into categories
 *   - '{{?DRAFT_EMAIL_RESPONSE}}' - Generate email response
 *   - '{{?TEXT_SUMMARIZATION}}' - Summarize long text
 *   - '{{?EXTRACT_ACTION_ITEMS}}' - Extract action items
 *   - '{{?LEAD_ENRICHMENT}}' - Enrich lead data
 * Create your own custom prompts in the Simple Translate configuration UI
 */
