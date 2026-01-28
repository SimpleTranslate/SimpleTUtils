# Sync Translation Service – Lead Description Translation Use Case

This repository contains the Apex service used to set up SimpleT's synchronous translation in Salesforce. It translates text immediately and returns results in the same execution, without background jobs.

**Service Name:** SyncTranslationServiceExample
**Type:** Apex Service (Synchronous)
**Use Case:** Translate text and get immediate results
**Execution:** Synchronous (blocking)

---

## Overview

This is a **synchronous translation service** that translates text and returns the translated result immediately. Unlike async translation:

1. You submit a translation request with the text, source language, and target language
2. Your code waits for the translation to complete (typically 2-10 seconds)
3. Translation results are returned immediately in the response
4. You can process results right away without background jobs
5. Perfect for immediate feedback and inline processing

---

## Prerequisites

- **SimpleT Package Installed:** The SimpleT translation package must be installed with `ST_TranslateInvocable`, `ST_TranslateService`, and `ST_TranslationWrapper`
- **Salesforce Org:** Apex classes and callouts supported
- **Permissions:** User executing translation must have the appropriate permissions and SimpleT API access
- **Translation Engine:** Verify "ST Google Translate Default" is configured in SimpleT settings
- **API Timeout:** Ensure adequate API callout time limits (sync translation blocks execution for 2-10 seconds)

---

## Components in This Repo

| Component | Type | Purpose |
|-----------|------|---------|
| **SyncTranslationServiceExample** | Apex Service | Provides methods for synchronous translation with immediate results |

---

## How It Works

1. **Submit Request:** Call a translation method with text, source language, and target language
2. **Create Wrapper:** Service creates an `ST_TranslationWrapper` with async mode disabled
3. **Call Service:** Calls `ST_TranslateInvocable.stTranslate()` and **waits for completion**
4. **Get Results:** Service returns immediately with translations in the response
5. **Process Inline:** Your code processes results right away (no polling needed)
6. **Update Records:** You can update records or use translations in your logic immediately

---

## Setup Requirements

### Prerequisites

Ensure SimpleT is properly configured:

1. Install the SimpleT package from AppExchange (if not already installed) https://www.simpletranslate.io/docs/salesforce/setup/installPackage/
2. Verify the translation engine "ST Google Translate Default" is active in SimpleT settings https://www.simpletranslate.io/docs/setup/translationEngine/default-engines
3. Ensure API credentials are set up in Salesforce (NamedCredential/External credential) https://www.simpletranslate.io/docs/salesforce/setup/authenticationSalesforce/
4. Ensure credentials are configured for your selected translation engine https://www.simpletranslate.io/docs/setup/translationEngine

---

## Installation Steps

### Step 1: Copy Apex Class to Your Org

1. Go to **Setup → Apex Classes**
2. Create a new class named `SyncTranslationServiceExample`
3. Paste the contents from [SyncTranslationServiceExample.cls](SyncTranslationServiceExample.cls)
4. Save the class

---

### Step 2: Test Basic Translation

Create a simple Apex script to test:

```apex
// Execute this in Anonymous Apex (Setup → Developer Console → Debug → Open Execute Anonymous)

String germanText = 'Guten Morgen, ich bin interessiert';
String englishText = SyncTranslationServiceExample.translateText(germanText, 'de', 'en_GB');
System.debug('Original: ' + germanText);
System.debug('Translated: ' + englishText);
```

Expected Output:
```
Original: Guten Morgen, ich bin interessiert
Translated: Good morning, I am interested
```

---

### Step 3: Create a Test Trigger (Optional)

To automatically translate new Lead descriptions:

1. Go to **Object Manager → Lead**
2. Click **Triggers** (or go to Setup → Triggers)
3. Create a new trigger named `LeadSyncTranslationTrigger`
4. Paste the following code:

```apex
trigger LeadSyncTranslationTrigger on Lead (before insert, before update) {

    for (Lead lead : Trigger.new) {

        // Translate from German to English synchronously
        Lead translatedLead = SyncTranslationServiceExample.translateLeadDescription(
            lead,
            'de',           // Source: German
            'en_GB'         // Target: English (UK)
        );

        // Update the lead reference with translated description
        lead.Description = translatedLead.Description;
    }
}
```

5. Save the trigger

---

## Performance Considerations

- **Blocking Execution:** Synchronous translation blocks your code execution while waiting (typically 2-10 seconds)
- **User Experience:** In Triggers and UI, users may experience delays while translation completes
- **Governor Limits:** Callout time limits apply (120 seconds max per callout)
- **Text Size:** For optimal performance, keep translations under 500 characters

---

## Synchronous vs Asynchronous

| Aspect | Synchronous (This Service) | Asynchronous (Queueable) |
|--------|------|----------|
| **Execution** | Blocks code execution | Non-blocking |
| **Return Time** | Waits for result (2-10 sec) | Returns immediately with job ID |
| **Processing** | Inline in your code | Background polling |
| **API Calls** | 1 callout | 1 callout + polling callouts |
| **User Wait Time** | Yes, feels immediate | No, user doesn't wait |
| **Best For** | Small translations, immediate need | Batch operations, large volumes |
| **Queueable Jobs** | None needed | 1 per translation |

---

## Troubleshooting

### Issue: Translation Returns Null

**Possible Causes:**
- Translation service not properly configured
- Invalid language codes
- Source text is empty
- API credentials not set up

**Solution:**
1. Check that SimpleT package is installed correctly
2. Verify language codes are valid (e.g., 'de', 'en_GB', not 'DE', 'EN')
3. Ensure source text is not empty: `if (String.isNotBlank(sourceText))`
4. Test in Developer Console with a simple text
5. Check debug logs for error messages

### Issue: "System.CalloutException: Read timed out"

**Cause:** Translation service took too long to respond

**Solution:**
1. Try with shorter text (less than 500 characters)
2. Check if SimpleT service is slow or overloaded
3. Try again in a few minutes
4. Consider using async translation (TranslationPollingQueueable) for large texts

### Issue: "INVALID_FIELD_FOR_INSERT_UPDATE"

**Cause:** Field permissions issue when updating Lead

**Solution:**
1. Verify your Salesforce user has permission to update the Description field
2. Check Field-Level Security for the Description field
3. Ensure no validation rules are preventing the update

### Issue: Code Waits Too Long

**Cause:** Synchronous translation blocks for 2-10+ seconds

**Solution:**
1. For immediate response without waiting, use async translation instead (AsyncTranslationQueueableUseCase)
2. For triggers, consider if users will notice the delay
3. Optimize text length to reduce translation time

---

## Limitations

- **Blocking:** Translation blocks code execution (2-10+ seconds)
- **User Experience:** In UI operations, users must wait for translation
- **Timeout Risk:** Translation can fail if it exceeds Salesforce's callout timeout (120 seconds)
- **Text Size:** Maximum ~100,000 characters per translation (varies by engine)
- **Sync character limit:** We recommend using the sync approach if you have less than 1,000 characters, otherwise we reccomend using the async approach to avoid hitting timeouts and Salesforce limits
- **Language Support:** Not all language pairs supported; check SimpleT engine documentation

---

## Related Documentation

- [Salesforce Callouts Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http_callouts.htm)
- [SimpleT Documentation](https://simplet.notion.site/documentation)
- [SimpleT Salesforce Setup](https://simplet.notion.site/salesforce-setup)
- [Async Translation Service](../Apex%20Async%20Translation%20Service/README.md) - For non-blocking translation

---

## Support

For issues or questions:

1. **Check Debug Logs** - Review Salesforce debug logs for detailed error messages
2. **Test Translation Directly** - Use Anonymous Apex to test the service
3. **Verify SimpleT Setup** - Ensure SimpleT is properly configured in your org
4. **Review Troubleshooting** - Check the Troubleshooting section above
5. **Contact Support** - Reach out to SimpleT support with debug logs
