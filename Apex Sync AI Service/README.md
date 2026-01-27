# Sync AI Service – Lead Enrichment and AI Processing Use Case

This repository contains the Apex service used to set up SimpleT's synchronous AI processing in Salesforce. It processes text with AI immediately and returns results in the same execution, without background jobs.

**Service Name:** SyncAIServiceExample
**Type:** Apex Service (Synchronous)
**Use Case:** AI-powered text processing with immediate results
**Execution:** Synchronous (blocking)

---

## Overview

This is a **synchronous AI service** that processes text using AI and returns results immediately. Unlike async AI processing:

1. You submit a text and AI instructions (prompt) to the AI service
2. Your code waits for the AI processing to complete (typically 3-10 seconds)
3. AI results are returned immediately in the response
4. You can process results right away without background jobs
5. Perfect for immediate feedback, enrichment, and inline processing

---

## Prerequisites

- **SimpleT Package Installed:** The SimpleT package must be installed with `ST_AIServiceInvocable`, `ST_AIInvocableWrapper`, and `ST_AIResponseDataWrapper`
- **Salesforce Org:** Apex classes and callouts supported
- **Permissions:** User executing AI processing must have appropriate permissions and SimpleT API access
- **AI Prompts Configured:** You must configure AI prompts/instructions in SimpleT settings
- **API Timeout:** Ensure adequate API callout time limits (sync AI processing blocks execution for 3-10 seconds)

---

## Components in This Repo

| Component | Type | Purpose |
|-----------|------|---------|
| **SyncAIServiceExample** | Apex Service | Provides methods for synchronous AI processing with immediate results |

---

## How It Works

1. **Submit Request:** Call an AI processing method with text and AI instructions/prompt
2. **Create Wrapper:** Service creates an `ST_AIInvocableWrapper` with async mode disabled
3. **Call Service:** Calls `ST_AIServiceInvocable.stAiService()` and **waits for completion**
4. **Get Results:** Service returns immediately with AI response in the `finalResponseMessage`
5. **Process Inline:** Your code processes results right away (no polling needed)
6. **Update Records:** You can update records or use results in your logic immediately

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
2. Create a new prompt with an API name (e.g., `LEAD_ENRICHMENT`)
3. Define the prompt instructions for the AI
4. Save and activate the prompt
5. Use `{{?LEAD_ENRICHMENT}}` format in your code

---

## Installation Steps

### Step 1: Copy Apex Class to Your Org

1. Go to **Setup → Apex Classes**
2. Create a new class named `SyncAIServiceExample`
3. Paste the contents from [SyncAIServiceExample.cls](SyncAIServiceExample.cls)
4. Save the class

---

### Step 2: Create AI Prompts

Before testing, create the AI prompts in SimpleT:

1. Go to SimpleT settings in your Salesforce org
2. Create a prompt with API name: `LEAD_ENRICHMENT`
   - Instructions: "Analyze the provided lead information and suggest potential opportunities, pain points, and recommended next steps for sales engagement."
3. Save the prompt

---

### Step 3: Test Lead Enrichment (Optional)

Test the Lead enrichment example:

```apex
Lead myLead = [SELECT Id, Company, Description FROM Lead WHERE Id = :leadId LIMIT 1];
String enrichment = SyncAIServiceExample.enrichLeadData(myLead);
System.debug('Enrichment: ' + enrichment);

// Optionally update the Lead
myLead.Description = enrichment;
update myLead;
```

---

## Configuration

### Creating Custom AI Prompts

To use the AI service, you must create prompts in SimpleT:

1. **Go to SimpleT Configuration**
   - Setup → SimpleT or your SimpleT admin interface
   - Navigate to AI Prompts or Instructions

2. **Create a New Prompt**
   - Set API Name: `LEAD_ENRICHMENT` (no spaces or special characters)
   - Set Display Name: "Lead Enrichment"
   - Define instructions for what the AI should do

3. **Example Prompts:**

   **LEAD_ENRICHMENT**
   ```
   Analyze the following lead information and provide:
   1. Potential opportunities based on company and industry
   2. Key pain points that this lead might have
   3. Recommended next steps for engagement
   ```

   **SENTIMENT_ANALYSIS**
   ```
   Analyze the sentiment of the provided text. Identify:
   1. Overall sentiment (positive, negative, mixed)
   2. Key emotions detected
   3. Specific aspects mentioned (product, service, price, etc.)
   ```

   **EXTRACT_ACTION_ITEMS**
   ```
   Extract all action items from the provided meeting notes.
   Format as a numbered list with:
   - Action item
   - Owner (if mentioned)
   - Due date (if mentioned)
   ```

4. **Save and Activate** the prompt in SimpleT

5. **Use in Code:**
   ```apex
   SyncAIServiceExample.processWithAI(text, '{{?SENTIMENT_ANALYSIS}}');
   SyncAIServiceExample.processWithAI(text, '{{?LEAD_ENRICHMENT}}');
   SyncAIServiceExample.processWithAI(text, '{{?EXTRACT_ACTION_ITEMS}}');
   ```

### Changing AI Model or Engine

To use a different AI model or engine, configure it in SimpleT settings (not in this code).

---

## Use Cases

### Sentiment Analysis

Analyze customer feedback or reviews:

```apex
String feedback = 'Love the features but customer service was terrible';
String sentiment = SyncAIServiceExample.processWithAI(feedback, '{{?SENTIMENT_ANALYSIS}}');
```

### Lead Enrichment

Add context and insights to Lead records:

```apex
Lead newLead = [SELECT Id, Company, Description FROM Lead WHERE Id = :leadId];
String enrichment = SyncAIServiceExample.enrichLeadData(newLead);
newLead.Description = enrichment;
update newLead;
```

---

## Performance Considerations

- **Blocking Execution:** Synchronous AI processing blocks your code execution while waiting (typically 3-10 seconds)
- **API Callout Time:** Each AI request counts as one API callout; monitor your callout time limits
- **User Experience:** In Triggers and UI, users may experience delays while AI processing completes
- **Governor Limits:** Callout time limits apply (120 seconds max per callout)
- **Text Size:** For optimal performance, keep text under 2,000 characters

---

## Synchronous vs Asynchronous

| Aspect | Synchronous (This Service) | Asynchronous (Queueable) |
|--------|------|----------|
| **Execution** | Blocks code execution | Non-blocking |
| **Return Time** | Waits for result (3-10 sec) | Returns immediately with Run ID |
| **Processing** | Inline in your code | Background processing via queueable |
| **API Calls** | 1 callout | 1 callout + polling callouts |
| **User Wait Time** | Yes, feels immediate | No, user doesn't wait |
| **Best For** | Single items, immediate need | Batch operations, large volumes |
| **Queueable Jobs** | None needed | 1 per AI request |

---

## Troubleshooting

### Issue: AI Processing Returns Null

**Possible Causes:**
- AI prompt not configured or API name incorrect
- Invalid prompt format (should be `{{?PROMPTAPINAME}}`)
- AI service credentials not set up
- User message is empty

**Solution:**
1. Verify prompt is created in SimpleT with correct API name
2. Check prompt format: `{{?PROMPTNAME}}` (no spaces)
3. Ensure source text is not empty: `if (String.isNotBlank(userMessage))`
4. Verify AI service credentials in SimpleT settings
5. Check debug logs for error messages

### Issue: "System.CalloutException: Read timed out"

**Cause:** AI processing took too long to respond

**Solution:**
1. Try with shorter text (less than 1,000 characters)
2. Check if AI service is slow or overloaded
3. Try again in a few minutes
4. Consider using async AI processing for large texts

### Issue: Prompt API Name Not Found

**Cause:** Prompt with the specified API name doesn't exist in SimpleT

**Solution:**
1. Check SimpleT configuration for the exact API name
2. Verify prompt is activated
3. Use correct format: `{{?PROMPT_API_NAME}}`
4. Create the prompt if it doesn't exist

### Issue: Code Waits Too Long

**Cause:** Synchronous AI processing blocks for 3-10+ seconds

**Solution:**
1. For immediate response without waiting, use async AI processing instead (AsyncAIQueueableUseCase)
2. For triggers, consider if users will notice the delay
3. Optimize text length to reduce processing time

### How to Check Debug Logs

1. Open Salesforce Setup
2. Go to **Logs → Debug Logs**
3. Create a log for your user
4. Run your AI code
5. Search for "AI" or exception messages in the logs

---

## Limitations

- **Blocking:** AI processing blocks code execution (3-10+ seconds)
- **User Experience:** In UI operations, users must wait for processing
- **Timeout Risk:** Processing can fail if it exceeds Salesforce's callout timeout (120 seconds)
- **Text Size:** Maximum ~100,000 characters per request (varies by AI engine)
- **Prompt Configuration:** Requires pre-configured prompts in SimpleT
- **API Limits:** Each AI request counts as one callout to AI provider

---

## Related Documentation

- [Salesforce Callouts Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http_callouts.htm)
- [SimpleT Documentation](https://simplet.notion.site/documentation)
- [Async AI Service](../Apex%20Async%20AI%20Service/README.md) - For non-blocking AI processing

---

## Support

For issues or questions:

1. **Check Debug Logs** - Review Salesforce debug logs for detailed error messages
2. **Test AI Directly** - Use Anonymous Apex to test the service
3. **Verify SimpleT Setup** - Ensure SimpleT and AI prompts are properly configured
4. **Review Troubleshooting** - Check the Troubleshooting section above
5. **Contact Support** - Reach out to SimpleT support with debug logs
