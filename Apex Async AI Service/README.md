# Async AI Service – Batch AI Processing Use Case

This repository contains the Apex service used to set up SimpleT's asynchronous AI processing in Salesforce. It submits AI tasks to the background without blocking execution, perfect for batch processing and long-running operations.

**Service Name:** AsyncAIServiceExample
**Type:** Apex Service with Background Processing
**Use Case:** Batch AI processing with background execution
**Execution:** Asynchronous (non-blocking)

---

## Overview

This is an **asynchronous AI service** that processes text with AI in the background without blocking your code. Unlike sync AI processing:

1. You submit an AI processing request with text and instructions
2. The service returns immediately with tracking IDs (Run ID and Thread ID)
3. Your code continues executing without waiting
4. AI processing happens in the background
5. Use the tracking IDs to retrieve results later when processing completes

---

## Prerequisites

- **SimpleT Package Installed:** The SimpleT package must be installed with `ST_AIServiceInvocable`, `ST_AIInvocableWrapper`, and `ST_AIResponseDataWrapper`
- **Salesforce Org:** Apex classes and background processing supported
- **Permissions:** User executing AI processing must have appropriate permissions and SimpleT API access
- **AI Prompts Configured:** You must configure AI prompts/instructions in SimpleT settings
- **Result Retrieval Method:** You'll need a way to retrieve results later using Run ID and Thread ID

---

## Components in This Repo

| Component | Type | Purpose |
|-----------|------|---------|
| **AsyncAIServiceExample** | Apex Service | Provides methods for async AI processing with background execution |

---

## How It Works

1. **Submit Request:** Call an AI processing method with text and AI instructions/prompt
2. **Create Wrapper:** Service creates an `ST_AIInvocableWrapper` with async mode enabled
3. **Start Processing:** Calls `ST_AIServiceInvocable.stAiService()` and returns **immediately**
4. **Get Tracking IDs:** Service returns with Run ID and Thread ID for tracking
5. **Continue Code:** Your code continues executing without waiting
6. **Background Processing:** AI processing happens in the background
7. **Retrieve Results:** Use Run ID and Thread ID to retrieve results when needed

---

## Setup Requirements

### Prerequisites

Ensure SimpleT is properly configured:

1. Install the SimpleT package from AppExchange (if not already installed) https://www.simpletranslate.io/docs/salesforce/setup/installPackage/
2. Configure AI prompts in SimpleT settings https://simplet.notion.site/documentation
3. Ensure API credentials are set up in Salesforce (NamedCredential/External credential) https://www.simpletranslate.io/docs/salesforce/setup/authenticationSalesforce/
4. Create custom AI prompts with API names (e.g., `LEAD_ENRICHMENT`, `SENTIMENT_ANALYSIS`)

### Creating AI Prompts

You must create prompts in the SimpleT configuration UI:

1. Go to SimpleT settings in your Salesforce org
2. Create a new prompt with an API name (e.g., `SENTIMENT_ANALYSIS`)
3. Define the prompt instructions for the AI
4. Save and activate the prompt
5. Use `{{?SENTIMENT_ANALYSIS}}` format in your code

---

## Installation Steps

### Step 1: Copy Apex Class to Your Org

1. Go to **Setup → Apex Classes**
2. Create a new class named `AsyncAIServiceExample`
3. Paste the contents from [AsyncAIServiceExample.cls](AsyncAIServiceExample.cls)
4. Save the class

---

### Step 2: Create AI Prompts

Before testing, create the AI prompts in SimpleT:

1. Go to SimpleT settings in your Salesforce org
2. Create a prompt with API name: `SENTIMENT_ANALYSIS`
   - Instructions: "Analyze the sentiment of the provided text. Identify overall sentiment (positive, negative, mixed) and key emotions detected."
3. Save the prompt

---

### Step 3: Test Async AI Processing

Create a simple Apex script to test:

```apex
// Execute this in Anonymous Apex (Setup → Developer Console → Debug → Open Execute Anonymous)

String feedback = 'The product is amazing but delivery was slow';
Map<String, String> jobIds = AsyncAIServiceExample.initiateAsyncAIProcessing(
    feedback,
    '{{?SENTIMENT_ANALYSIS}}'
);

if (jobIds != null) {
    System.debug('Processing started');
    System.debug('RunId: ' + jobIds.get('runId'));
    System.debug('ThreadId: ' + jobIds.get('threadId'));
} else {
    System.debug('Failed to initiate async processing');
}
```

Expected Output:
```
Processing started
RunId: run_abc123def456
ThreadId: thread_xyz789
```

---

### Step 4: Test Batch Processing (Optional)

Test batch analysis of multiple Leads:

```apex
List<Lead> leads = [SELECT Id, Description FROM Lead WHERE Description != null LIMIT 10];
Map<String, Map<String, String>> jobs = AsyncAIServiceExample.batchAnalyzeLeadSentiment(leads);

System.debug('Started ' + jobs.size() + ' background analysis jobs');
for (String leadId : jobs.keySet()) {
    System.debug('Lead ' + leadId + ' RunId: ' + jobs.get(leadId).get('runId'));
}
```

---

## Configuration

### Creating Custom AI Prompts

To use the AI service, you must create prompts in SimpleT:

1. **Go to SimpleT Configuration**
   - Setup → SimpleT or your SimpleT admin interface
   - Navigate to AI Prompts or Instructions

2. **Create a New Prompt**
   - Set API Name: `SENTIMENT_ANALYSIS` (no spaces or special characters)
   - Set Display Name: "Sentiment Analysis"
   - Define instructions for what the AI should do

3. **Example Prompts:**

   **SENTIMENT_ANALYSIS**
   ```
   Analyze the sentiment of the provided text. Identify:
   1. Overall sentiment (positive, negative, mixed)
   2. Key emotions detected
   3. Specific aspects mentioned
   ```

   **CASE_CLASSIFICATION**
   ```
   Classify the provided case description into categories.
   Identify priority (high/medium/low) and category (technical/billing/general)
   ```

   **LEAD_ENRICHMENT**
   ```
   Analyze the lead information and suggest:
   1. Potential opportunities
   2. Key pain points
   3. Recommended next steps
   ```

4. **Save and Activate** the prompt in SimpleT

5. **Use in Code:**
   ```apex
   AsyncAIServiceExample.initiateAsyncAIProcessing(text, '{{?SENTIMENT_ANALYSIS}}');
   AsyncAIServiceExample.initiateAsyncAIProcessing(text, '{{?CASE_CLASSIFICATION}}');
   ```

---

## Performance Considerations

- **Non-Blocking:** Async AI processing returns immediately without waiting
- **Background Execution:** AI processing happens in background (3-30 seconds typical)
- **Scalability:** Perfect for processing hundreds or thousands of records
- **API Callout Efficiency:** One callout per request; multiple requests handled in parallel
- **Result Retrieval:** You must implement your own mechanism to retrieve results using Run ID
- **Queue Management:** SimpleT handles background processing queue internally

---

## Synchronous vs Asynchronous

| Aspect | Synchronous (Sync AI) | Asynchronous (This Service) |
|--------|------|----------|
| **Execution** | Blocks code execution | Non-blocking |
| **Return Time** | Waits for result (3-10 sec) | Returns immediately with tracking IDs |
| **What Returns** | `finalResponseMessage` with result | `runId` and `threadId` for tracking |
| **Processing** | Inline in your code | Background via SimpleT |
| **User Wait Time** | Yes | No |
| **Best For** | Single items, immediate need | Batch operations, large volumes |
| **Ideal For** | Flows, Triggers, UI actions | Scheduled jobs, bulk processing |
| **Setup Complexity** | Simple | More - need result retrieval mechanism |

---

## Troubleshooting

### Issue: Async Processing Doesn't Start

**Possible Causes:**
- AI prompt not configured
- Invalid prompt format
- AI service credentials not set up
- User message is empty

**Solution:**
1. Verify prompt is created in SimpleT with correct API name
2. Check prompt format: `{{?PROMPTNAME}}` (no spaces)
3. Ensure source text is not empty: `if (String.isNotBlank(userMessage))`
4. Verify AI service credentials in SimpleT settings
5. Check debug logs for error messages

### Issue: initiateAsyncAIProcessing Returns Null

**Possible Causes:**
- Response doesn't contain tracking IDs
- Service returned invalid response
- Network or API error

**Solution:**
1. Check debug logs for "Async AI processing initiation error"
2. Verify AI service is working in SimpleT
3. Test with simple text first
4. Check SimpleT configuration

### Issue: Can't Retrieve Results Later

**Cause:** No mechanism implemented to store and retrieve tracking IDs

**Solution:**
1. Create custom object to store Run ID and Thread ID
2. Implement retrieval logic using SimpleT APIs
3. Use Run ID and Thread ID to query for results

### How to Check Debug Logs

1. Open Salesforce Setup
2. Go to **Logs → Debug Logs**
3. Create a log for your user
4. Run your async AI code
5. Search for "Async AI" or exception messages in the logs

---

## Limitations

- **Non-Immediate Results:** Results not immediately available; must retrieve later
- **Tracking Required:** Must store Run ID and Thread ID to retrieve results
- **Result Retrieval:** Requires additional implementation to fetch and process results
- **Text Size:** Maximum ~100,000 characters per request (varies by AI engine)
- **Prompt Configuration:** Requires pre-configured prompts in SimpleT
- **API Limits:** Each request counts as one callout; monitor API usage
- **Background Processing Time:** Results take 3-30+ seconds to process

---

## Related Documentation

- [Salesforce Batch Processing](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm)
- [SimpleT Documentation](https://simplet.notion.site/documentation)
- [Sync AI Service](../Apex%20Sync%20AI%20Service/README.md) - For immediate AI processing results

---

## Support

For issues or questions:

1. **Check Debug Logs** - Review Salesforce debug logs for detailed error messages
2. **Test Async Directly** - Use Anonymous Apex to test the service
3. **Verify SimpleT Setup** - Ensure SimpleT and AI prompts are properly configured
4. **Review Troubleshooting** - Check the Troubleshooting section above
5. **Contact Support** - Reach out to SimpleT support with debug logs
