trigger KnowledgeTranslationTrigger on Knowledge__kav (after insert) {
    // Collect Knowledge IDs for translation
    Set<Id> knowledgeIds = new Set<Id>();

    for(Knowledge__kav knowledge : Trigger.new) {
        knowledgeIds.add(knowledge.Id);
    }

    if(!knowledgeIds.isEmpty()) {
        // Call future method to handle translation (async callout)
        KnowledgeTranslationService.translateKnowledgeArticles(knowledgeIds);
    }
}