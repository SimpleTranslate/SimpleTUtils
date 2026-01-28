# Async Translation Service – Lead Description Translation Use Case

This repository contains the Apex service and queueable job used to set up SimpleT's asynchronous translation in Salesforce. It automatically translates Lead descriptions in the background without blocking your code.

**Service Name:** AsyncTranslationQueueableUseCase
**Type:** Apex Service with Queueable
**Use Case:** Translate Lead Description asynchronously
**Trigger Event:** Lead creation or manual invocation

---

## Overview

This is an **asynchronous translation service** that translates a Lead's description without waiting for the translation to complete. Instead of blocking your code execution:

1. You submit a translation request with the text, source language, and target language
2. The service returns immediately with a job ID
3. A Queueable job automatically polls for translation results in the background
4. When translation completes, the Lead record is automatically updated
5. No impact on API callout timeouts or user experience

---

## Prerequisites

- **SimpleT Package Installed:** The SimpleT translation package must be installed with `ST_TranslateInvocable`, `ST_TranslateService`, and `ST_TranslationWrapper`
- **Salesforce Org:** Apex classes and queueable jobs supported
- **Permissions:** User executing translation must have Lead modify permissions and SimpleT API access
- **Translation Engine:** Verify "ST Google Translate Default" is configured in SimpleT settings

---

## Components in This Repo

| Component | Type | Purpose |
|-----------|------|---------|
| **AsyncTranslationQueueableUseCase** | Apex Service | Entry point method for submitting translations |
| **TranslationPollingQueueable** | Apex Queueable | Background job that polls for translation results and updates records |

---

## How It Works

1. **Submit Request:** Call `AsyncTranslationQueueableUseCase.translateLeadDescriptionAsync()` with Lead ID, text, source language, and target language
2. **Create Wrapper:** Service creates an `ST_TranslationWrapper` with async mode enabled
3. **Get Job ID:** Calls `ST_TranslateInvocable.stTranslate()` which returns immediately with a job ID
4. **Enqueue Polling:** Submits `TranslationPollingQueueable` to poll for results
5. **Poll Status:** Queueable checks translation status every 1 minute (up to 5 attempts)
6. **On Complete:** When translation finishes, updates the Lead's Description field
7. **On Timeout:** If translation doesn't complete in 5 attempts, logs error and stops

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

### Step 1: Copy Apex Classes to Your Org

1. Go to **Setup → Apex Classes**
2. Create a new class named `AsyncTranslation`
3. Paste the contents from [AsyncTranslation.cls](AsyncTranslation.cls)
4. Save the class
5. Create another class named `TranslationPollingQueueable`
6. Paste the contents from [TranslationPollingQueueable.cls](TranslationPollingQueueable.cls)
7. Save the class
8. Adapt to your orgs needs

**Note:** Do NOT modify `TranslationPollingQueueable.cls` unless you need to change polling behavior for this example.

---

### Step 2: Create a Test Trigger

To test the service, create a simple Apex trigger on the Lead object:

1. Go to **Object Manager → Lead**
2. Click **Triggers** (or go to Setup → Triggers)
3. Create a new trigger named `LeadTranslationTrigger`
4. Paste the following code:

```apex
trigger LeadTranslationTrigger on Lead (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {

        for (Lead lead : Trigger.new) {

            // Only translate if description exists
            if (String.isNotBlank(lead.Description)) {

                // Translate from German to English asynchronously
                AsyncTranslationQueueableUseCase.translateLeadDescriptionAsync(
                    lead.Id,
                    lead.Description,
                    'de',           // Source: German
                    'en_GB'         // Target: English (UK)
                );
            }
        }
    }
}
```

5. Save the trigger

---

### Step 3: Test the Implementation

1. In Salesforce, go to **Leads** tab
2. Click **New Lead**
3. Fill in required fields (Last Name, Company)
4. In the **Description** field, paste a German sentence:
   ```
   Guten Morgen, ich bin an Ihren Produkten interessiert
   ```
5. Click **Save**
6. Wait a minute for the translation service to process
7. Refresh the page and check the Description field
8. You should see the English translation: "Good morning, I am interested in your products"

---

## Performance Considerations

- **Asynchronous Execution:** The translation job runs in the background asynchronously, so it doesn't block your code
- **Polling Delay:** Queueable polls every 1 minute; expect 2-10 seconds for translation to complete typically and up to a minute for large amounts of data
- **Max Attempts:** Job retries up to 5 times (5 minute maximum wait) before giving up

---

## Troubleshooting

### Issue: Lead Description Not Updated

**Possible Causes:**
- Translation job failed - check debug logs
- Polling timed out after 5 attempts - translation took too long
- Network issues prevented queueable from running

**Solution:**
1. Check Salesforce **Debug Logs** for errors:
   - Setup → Logs → Debug Logs
   - Create a log for your user, run the code, and review
   - Search for "TranslationPollingQueueable" or "AsyncTranslationQueueable"
2. Check that source text is not empty
3. Verify translation engine is active in SimpleT settings

### Issue: "Failed to initiate translation job"

**Cause:** Translation service returned invalid response

**Solution:**
1. Verify SimpleT package is installed correctly
2. Check translation engine name matches exactly (case-sensitive)
3. Test translation using `AsyncTranslationServiceExample.cls`
4. Verify API credentials are configured in Salesforce

### Issue: "exceeded max poll attempts"

**Cause:** Translation didn't complete within 5 polling attempts (5+ minutes)

**Solution:**
1. Try with shorter text first (under 500 characters)
2. Check if SimpleT translation service is slow or overloaded
3. Review Salesforce debug logs for translation service errors
4. Contact SimpleTUtils support if persistent

### Issue: Queueable Failed to Execute

**Cause:** Apex Governor Limits exceeded or system error

**Solution:**
1. Check **Setup → Monitoring → Apex Jobs** for failed jobs
2. Review **Debug Logs** for governor limit errors
3. If caused by callouts, ensure "Allow Callouts" is enabled
4. Try with less text to reduce callout overhead

---

## Limitations

- **Timing:** Expect 2-10 seconds for translation; maximum 5 minutes (5 polling attempts)
- **Text Size:** Maximum ~100,000 characters per translation (varies by engine)
- **Sync character limit:** We recommend using the async approach if you have more than 1,000 characters to avoid hitting timeouts and Salesforce limits
- **Queueable Limits:** Maximum 50 queueable jobs per transaction
- **Language Support:** Not all language pairs supported; check SimpleT engine documentation

---

## Related Documentation

- [Salesforce Queueable Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueable.htm)
- [SimpleT Documentation](https://simplet.notion.site/documentation)
- [SimpleT Salesforce Setup](https://simplet.notion.site/salesforce-setup)

---

## Support

For issues or questions:

1. **Check Debug Logs** - Review Salesforce debug logs for detailed error messages
2. **Test Translation Manually** - Use `AsyncTranslationServiceExample.cls` to test
3. **Verify SimpleT Setup** - Ensure SimpleT is properly configured in your org
4. **Review Troubleshooting** - Check the Troubleshooting section above
5. **Contact Support** - Reach out to SimpleT support with debug logs
