# SimpleT Real Time Translation Flow - Case Object Use Case

## Overview

This is a **Record-Triggered Flow** that automatically translates Case record descriptions in real-time whenever a new Case is created. It integrates with the SimpleT (Simple Translate) package to provide multi-language translation capabilities using Google Translate.

**Flow Name:** SimpleT Real Time Translation
**Type:** Record-Triggered Flow
**Trigger Object:** Case
**Trigger Event:** After Record Creation

---

## How It Works

1. **Trigger:** A new Case record is created
2. **Language Setup:** The flow adds supported languages (In this example those are: English, German, French, Italian, Portuguese)
3. **Translation:** Calls the SimpleT translation API to translate the Case Description into all selected languages
4. **Processing:** Loops through translation results
5. **German Filter:** Identifies German translations and updates the Case record (This example uses german, you can set it to the language you need)
6. **Update:** Stores the German translation in the Case's standard `Description` field

---

## Setup Requirements

### Prerequisites

- **SimpleT Package Installed:** This flow requires the SimpleT translation package with the `simpleT__ST_TranslateInvocable` Apex action
- **Salesforce Org:** Flow is built for Salesforce with Lightning Flow Builder
- **Permissions:** User executing the flow must have appropriate Case update permissions

### SimpleT Configuration

Ensure SimpleT is properly configured:

1. Install the SimpleT package from AppExchange (if not already installed)
2. Verify the translation engine "ST Google Translate Default" is active in SimpleT settings (In this example we use Google Translate, you can adjust it to other SimpleT supported engines)
3. Ensure API credentials are configured for the selected translation engine

---

## Flow Variables

### Input Variables

| Variable Name | Type | Collection | Purpose |
|---|---|---|---|
| `agentLanguage` | String | Yes | Collection of language codes to translate into. In this example it is populated by the flow with: `en`, `de`, `fr`, `it`, `pt` |

### Output Variables

| Variable Name | Type | Collection | Purpose |
|---|---|---|---|
| `translationResults` | Apex (ST_TranslationResponseWrapper) | Yes | Contains translation results from SimpleT API with language codes and translated text |

---

## Flow Elements

### 1. **Start: Create Case Trigger**
- **Type:** Record Trigger
- **Object:** Case
- **Event:** RecordAfterSave (Create)
- **Execution:** AsyncAfterCommit (asynchronous after commit)
- **Next:** Proceeds to "Add language" assignment

### 2. **Add language (Assignment)**
- **Purpose:** Populates the `agentLanguage` collection with supported language codes
- **Languages Added:**
  - `en` - English
  - `de` - German
  - `fr` - French
  - `it` - Italian
  - `pt` - Portuguese
- **Next:** Proceeds to "Translate Case" action call

### 3. **Translate Case (Apex Action Call)**
- **Action:** `simpleT__ST_TranslateInvocable`
- **Engine:** ST Google Translate Default (or others if you choose them)
- **Input Parameters:**
  - `engine`: "ST Google Translate Default"
  - `targetLanguages`: The `agentLanguage` collection
  - `text`: Case Description (`$Record.Description`)
- **Output:** Stores results in `translationResults` variable
- **Next:** Proceeds to "Loop through translations"

### 4. **Loop through translations (Loop)**
- **Collection Reference:** `translationResults`
- **Iteration Order:** Ascending
- **Loop Item Access:** Use `Loop_through_translations.language` and `Loop_through_translations.translation`
- **Next:** Proceeds to "Check if translation is German" decision

### 5. **Check if translation is German (Decision)**
- **Rule:** "Is German"
  - **Condition:** `Loop_through_translations.language` equals `"de"`
  - **Outcome:** Proceeds to "Update with translations"
- **Default:** Returns to loop for next iteration
- **Purpose:** Filters for German translation only

### 6. **Update with translations (Record Update)**
- **Record:** Current Case (`$Record`)
- **Field Updated:** `Description` (standard Case field)
- **Value:** German translation from `Loop_through_translations.translation`
- **Next:** Returns to loop for next iteration

---

## Manual Flow Setup Guide

If you want to simply import the flow from the metadata file skip to "Installation Steps". If you prefer to create this flow manually from scratch in Lightning Flow Builder, follow these detailed steps:

### Create a New Flow

1. Navigate to **Setup → Flows**
2. Click **New Flow**
3. Choose **Record-Triggered Flow**

### Configure the Flow Trigger

1. In the canvas, click the **Start** element
2. Configure the following:
   - **Object**: Case
   - **Trigger**: When a record is created
   - **Optimization**: Select **Actions and Related Records** and toggle the **Add Asynchronous Path** option

### Create the agentLanguage Variable

1. In the toolbox click **New Resource**
2. Configure:
   - **Resource Type**: Variable
   - **Variable Name**: `agentLanguage`
   - **Data Type**: Text
   - **Collection**: Yes (toggle on)
   - **Available for input**: Yes
   - **Available for output**: No
3. Click **Done**

### Create the translationResults Variable

1. In the toolbox click **New Resource**
2. Configure:
   - **Resource Type**: Variable
   - **Variable Name**: `translationResults`
   - **Data Type**: Apex-Defined
   - **Apex Class**: Select `simpleT__ST_TranslationResponseWrapper`
   - **Collection**: Yes (toggle on)
   - **Available for input**: No
   - **Available for output**: Yes
3. Click **Done**

### Add the "Add language" Assignment Element

1. On the asynchronous path click **+** → **Assignment**
2. Label: `Add language`
3. Add these assignment items (click **Add Assignment** for each):
   - **Assign to**: `agentLanguage` | **Operator**: Add | **Value**: `en`
   - **Assign to**: `agentLanguage` | **Operator**: Add | **Value**: `de`
   - **Assign to**: `agentLanguage` | **Operator**: Add | **Value**: `fr`
   - **Assign to**: `agentLanguage` | **Operator**: Add | **Value**: `it`
   - **Assign to**: `agentLanguage` | **Operator**: Add | **Value**: `pt`
4. Click **Done**

### Add the "Translate Case" Action Call

1. Click **+** → **Action**
2. Search for and select `simpleT__ST_TranslateInvocable`
3. Label: `Translate Case`
4. Configure Input Parameters:
   - **Source Text**: Field or Variable → `{!$Record.Description}`
   - **Target Languages**: Variable → `{!agentLanguage}` (collection)
   - **Translation Engine**: Text value → `ST Google Translate Default`
5. Make sure the `Manually assign variables (advanced)` checkbox is selected
6. Configure Output:
   - **Translation Results**: `{!translationResults}`

### Add the "Loop through translations" Loop

1. Click **+** → **Loop**
2. Label: `Loop through translations`
3. Configure:
   - **Collection**: `{!translationResults}`
   - **Loop Order**: First item to last item

### Add the "Check if translation is German" Decision (inside the loop)

1. Inside the loop, click **+** → **Decision**
2. Label: `Check if translation is German`
3. Select `Manually Set Conditions`
4. Add an Outcome:
   - **Outcome Label**: `Is German`
   - **Condition Requirements**: All Conditions Are Met (AND)
   - **Condition**: `{!Loop_through_translations.language}` | **Equals** | `de`

### Add the "Update with translations" Record Update (inside the loop)

1. On the "Is German" outcome click **+** → **Update Records**
2. Label: `Update with translations`
3. Configure:
   - **How to find records to update?**: Use the case record that triggered the flow
4. Add an input assignment:
   - **Field**: `Description` (standard field)
   - **Value**: `{!Loop_through_translations.translation}`

### Save and Activate

1. Click **Save** in the top-right
2. Enter Flow Name: `SimpleT Real Time Translation`
3. Enter Flow Description (optional)
4. Click **Save**
5. Click **Activate** to enable the flow
6. Confirm activation

---

## Installation Steps

### Step 1: Deploy the Flow
1. In Salesforce Setup, navigate to **Flows**
2. Click **New Flow** or import the flow metadata file
3. Alternatively, use Salesforce CLI to deploy:
   ```bash
   sfdx force:source:deploy -p force-app/main/default/flows/SimpleT_Real_Time_Translation.flow-meta.xml
   ```

### Step 2: Activate the Flow
1. Open the flow in Lightning Flow Builder
2. Click **Activate** button
3. Confirm activation

### Step 3: Test the Flow
1. Create a new Case record with a Description (e.g., "Hello, this is a test case")
2. After creation, navigate back to the Case record
3. Check the `Description` field to verify it contains the German translation (Since it runs asynchronously it could take a moment to update the field)
4. Check Salesforce debug logs to troubleshoot if needed

---

## Configuration Options

### Changing Supported Languages

To modify the languages the flow translates into:

1. Edit the flow in Lightning Flow Builder
2. Click the "Add language" assignment element
3. Modify or add language codes in the assignment items
4. **Common language codes:**
   - `en` - English
   - `de` - German
   - `fr` - French
   - `it` - Italian
   - `pt` - Portuguese
   - `es` - Spanish
   - `ja` - Japanese
   - `zh` - Chinese
5. Update the German check decision if changing languages
6. Save and reactivate the flow

### Changing Translation Engine

To use a different translation engine:

1. Edit the flow
2. Click the "Translate Case" action call
3. Change the `engine` input parameter value
4. Verify the engine name matches your SimpleT configuration
5. Save and reactivate

---

## Performance Considerations

- **Asynchronous Execution:** The flow runs asynchronously after Case creation (AsyncAfterCommit), so it won't block the user
- **API Limits:** Each Case creation consumes one SimpleT API call; monitor API usage
- **Loop Processing:** The flow loops through all translations but only updates on German match; adjust decision logic if needed

---

## Related Documentation

- [Salesforce Flow Documentation](https://help.salesforce.com/s/articleView?id=sf.flow_intro.htm)
- [SimpleT Documentation](https://www.simpletranslate.io/docs/salesforce/components/translate/)
- [Record-Triggered Flows](https://help.salesforce.com/s/articleView?id=sf.flow_record_triggered.htm)

---

## Support

For issues or questions:
1. Review the Troubleshooting section in the SimpleT documentation
2. Check Salesforce Flow Debug Logs
4. Contact your Salesforce administrator
