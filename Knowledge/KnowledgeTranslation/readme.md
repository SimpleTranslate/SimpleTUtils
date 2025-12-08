# Knowledge Translation Service – Setup Guide

This repository contains the Apex service and trigger used to set up SimpleT's Knowledge Article translation tasks in Salesforce. Follow the steps below to configure your Salesforce org.

---

## Prerequisites

**Salesforce org with Lightning Knowledge enabled**

**Multiple Languages enabled under:**  
*Setup → Knowledge Settings → Language Settings*

**Appropriate user permissions:**
- Customize Application  
- Modify All Data  
- Manage Knowledge  

---

## Components in This Repo

- **Apex Service** — Handles creation logic for translation versions  
- **Apex Trigger** — Invokes the service when a Knowledge article is created or updated  

Copy and paste these files into your Salesforce org via:

- Salesforce's setup interface.

---

## Installation Steps

### 1. Enable Multiple Knowledge Languages

1. Go to *Setup → Knowledge Settings*  
2. Enable **Multiple Languages**  
3. Add the languages in which article translations should exist

---

### 2. Create necessary custom fields on the Knowledge object

1. Go to *Object Manager → Knowledge → Fields & Relationships*  
2. Create a new custom field  
3. Select **Rich Text Area** as the data type  
4. Name the field **"Answer"**

---

### 3. Create an Apex service class

1. Go to *Setup → Apex Classes*  
2. Create a new class  
3. Paste the **KnowledgeTranslationHandler** code

---

### 3. Create a Knowledge trigger

1. Go to *Object Manager → Knowledge → Fields & Relationships*  
2. Create a new trigger  
3. Paste the **KnowledgeTranslationTrigger** code

---

## Assign Permissions

Ensure users who create or review translations have:

- Access to the Knowledge object  
- Access to the specific languages they will translate  

---

## Test the Trigger

1. Create a new Knowledge article in your master language  
2. Save it  
3. Confirm that the translation works by clicking on the **"Submit for translation"** button in the highlights panel  
4. Select the languages you want to create the new draft versions in  
5. Verify that the different versions of draft are created by switching between versions in the **Translation Switcher** component

---
