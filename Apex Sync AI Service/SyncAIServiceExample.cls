/**
 * @description Use Case Examples: Synchronous AI Service
 * This class demonstrates how to use the ST_AIServiceInvocable service synchronously
 * to process text with AI and get immediate results without waiting for background jobs.
 *
 * Scenario: Enrich Lead data, generate email responses, classify cases, summarize content,
 * and perform other AI-powered text processing instantly and process the results
 * immediately in your code flow.
 */
public with sharing class SyncAIServiceExample {

    /**
     * @description Processes text synchronously using AI with custom instructions.
     * The AI processing completes immediately and returns the result.
     *
     * @param userMessage The text to process or question to ask the AI
     * @param aiInstructions The AI instructions/prompt to guide the processing (e.g., '{{?SENTIMENT_ANALYSIS}}')
     * @return The AI response, or null if processing failed
     *
     * Example:
     *   String feedback = 'The product is amazing but delivery was slow';
     *   String analysis = processWithAI(feedback, '{{?SENTIMENT_ANALYSIS}}');
     *   System.debug('Analysis: ' + analysis);  // Returns sentiment analysis result
     */
    public static String processWithAI(String userMessage, String aiInstructions) {
        ST_AIInvocableWrapper wrapper = new ST_AIInvocableWrapper();
        wrapper.userMessage = userMessage;
        wrapper.aiInstructions = aiInstructions;
        wrapper.executeAsync = false;  // Key: Set to false for synchronous mode

        try {
            List<ST_AIResponseDataWrapper> responseList = ST_AIServiceInvocable.stAiService(
                new List<ST_AIInvocableWrapper>{ wrapper }
            );

            if (responseList != null && !responseList.isEmpty()) {
                ST_AIResponseDataWrapper response = responseList[0];

                if (String.isNotBlank(response.finalResponseMessage)) {
                    return response.finalResponseMessage;
                }
            }

            System.debug(LoggingLevel.WARN, 'AI service returned no response');
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Synchronous AI processing error: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Example 5: Extract action items from meeting notes synchronously
     * Use case: Automatically identify and extract action items from meeting notes
     * to create tasks or update records
     *
     * @param meetingNotes The meeting notes text
     * @return The extracted action items
     *
     * Example:
     *   String notes = 'Meeting with John about Q1 strategy. Need to update pricing...';
     *   String actionItems = extractActionItems(notes);
     *   System.debug('Action Items: ' + actionItems);
     *   // Now parse and create tasks
     */
    public static String extractActionItems(String meetingNotes) {
        if (String.isBlank(meetingNotes)) {
            System.debug(LoggingLevel.WARN, 'Meeting notes are blank');
            return null;
        }

        String actions = processWithAI(
            meetingNotes,
            '{{?EXTRACT_ACTION_ITEMS}}'
        );

        return actions;
    }

    /**
     * @description Example: Enrich Lead with AI-generated details synchronously
     * Use case: Use AI to expand on a Lead's initial inquiry and generate
     * additional context or suggested next steps
     *
     * @param lead The Lead record to enrich
     * @return The enriched details to add to the Lead
     *
     * Example:
     *   Lead newLead = [SELECT Id, Company, Description FROM Lead WHERE Id = :leadId];
     *   String enrichment = enrichLeadData(newLead);
     *   newLead.Description = enrichment;
     *   update newLead;
     */
    public static String enrichLeadData(Lead lead) {
        if (lead == null) {
            System.debug(LoggingLevel.WARN, 'Lead is null');
            return null;
        }

        String leadInfo = 'Company: ' + (lead.Company != null ? lead.Company : 'Unknown') +
                         ', Current info: ' + (lead.Description != null ? lead.Description : 'No details');

        String enrichment = processWithAI(
            leadInfo,
            '{{?LEAD_ENRICHMENT}}'
        );

        return enrichment;
    }
}

/**
 * USAGE EXAMPLES:
 *
 * 1. Lead newLead = [SELECT Id, Company, Description FROM Lead WHERE Id = :leadId];
 *    String enrichment = SyncAIServiceExample.enrichLeadData(newLead);
 *    newLead.Description = enrichment;
 *    update newLead;
 *
 * HOW IT WORKS (SYNCHRONOUS):
 * 1. Create an ST_AIInvocableWrapper with userMessage and aiInstructions
 * 2. Set executeAsync = false to enable synchronous mode (this is KEY!)
 * 3. Call ST_AIServiceInvocable.stAiService() which WAITS for AI processing to complete
 * 4. Service blocks execution until AI processing is finished (typically 3-10 seconds)
 * 5. Immediately returns a list of ST_AIResponseDataWrapper with populated finalResponseMessage
 * 6. Your code can process results right away without waiting for background jobs
 * 7. Perfect for immediate feedback, inline processing, and direct responses
 *
 * SYNCHRONOUS VS ASYNCHRONOUS:
 * Synchronous (this file):
 *   - Returns immediately with AI response in finalResponseMessage
 *   - Blocks code execution while waiting (3-30 seconds typical)
 *   - No queueable jobs needed
 *   - Use when you need results right away for immediate processing
 *   - Perfect for Flows, Triggers, decision logic, and user actions
 *   - Best for single items or small batches
 *
 * Asynchronous (AsyncAIQueueableUseCase):
 *   - Returns immediately with Run ID and Thread ID
 *   - Doesn't block code execution
 *   - Polls in background via queueable
 *   - Use for large volumes or long-running operations
 *   - Better for batch operations and heavy processing
 *   - Use run ID to retrieve final response later
 *
 * IMPORTANT: Setting up AI Instructions (Prompts)
 * The aiInstructions parameter uses the format: '{{?PROMPTAPINAME}}'
 * You must have the prompt configured in the Simple Translate UI with the corresponding API name.
 * Common prompt patterns:
 *   - '{{?LEAD_ENRICHMENT}}' - Enrich lead data
 * Create your own custom prompts in the Simple Translate configuration UI
 */
