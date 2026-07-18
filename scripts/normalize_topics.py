"""
Normalize PYQ topic tags across all exam files.
Collapses variant spellings/names into one canonical label per topic.
"""

import json
from pathlib import Path

BASE = Path(__file__).parent.parent / "assets" / "data"

TOPIC_MAP = {
    # ── Voice ──────────────────────────────────────────────────────────────────
    "Active and Passive Voice":          "Voice Change",
    "Active-Passive Voice":              "Voice Change",
    "Active/Passive Voice":              "Voice Change",
    "Voice (Active-Passive)":            "Voice Change",
    "Grammar (Passive Voice)":           "Voice Change",
    "Grammar - Voice Change":            "Voice Change",

    # ── Narration ──────────────────────────────────────────────────────────────
    "Direct-Indirect Speech":                        "Narration",
    "Direct/Indirect Speech":                        "Narration",
    "Narration (Direct-Indirect Speech)":            "Narration",
    "Narration (Direct-Indirect)":                   "Narration",
    "Narration (Direct/Indirect Speech)":            "Narration",
    "Grammar - Narration (Direct-Indirect Speech)":  "Narration",
    "Grammar - Narration/Indirect Speech":           "Narration",

    # ── Error Spotting ─────────────────────────────────────────────────────────
    "Error Detection":                          "Error Spotting",
    "Error Detection (Sentence Improvement)":   "Error Spotting",
    "Error spotting":                           "Error Spotting",
    "Error Spotting (Sentence-level)":          "Error Spotting",
    "Grammar - Error Spotting":                 "Error Spotting",
    "Grammar - Spotting Errors":                "Error Spotting",
    "Grammar - Sentence Correction":            "Error Spotting",
    "Spotting Errors":                          "Error Spotting",
    "Sentence Correction":                      "Error Spotting",
    "Sentence Correction (Word Swap)":          "Error Spotting",
    "Grammatically Incorrect Sentence":         "Error Spotting",
    "Grammatically Correct Sentence":           "Error Spotting",

    # ── Idioms & Phrases ───────────────────────────────────────────────────────
    "Idiom":                      "Idioms & Phrases",
    "Idiom (Passage-based)":      "Idioms & Phrases",
    "Idiom Fill in the Blank":    "Idioms & Phrases",
    "Idiom Meaning":              "Idioms & Phrases",
    "Idioms":                     "Idioms & Phrases",
    "Idioms / Fill in the Blanks":"Idioms & Phrases",
    "Idioms and Phrases":         "Idioms & Phrases",
    "Idioms and Proverbs":        "Idioms & Phrases",
    "Vocabulary - Idioms":        "Idioms & Phrases",

    # ── One Word Substitution ──────────────────────────────────────────────────
    "One-word Substitution":               "One Word Substitution",
    "One-word substitution":               "One Word Substitution",
    "One-Word Substitution":               "One Word Substitution",
    "Vocabulary - One Word Substitution":  "One Word Substitution",
    "Vocabulary (One-word Substitution)":  "One Word Substitution",

    # ── Synonym ────────────────────────────────────────────────────────────────
    "Synonyms":                  "Synonym",
    "Vocabulary - Synonym":      "Synonym",
    "Vocabulary - Synonyms":     "Synonym",
    "Vocabulary (Synonyms)":     "Synonym",

    # ── Antonym ────────────────────────────────────────────────────────────────
    "Antonyms":                  "Antonym",
    "Vocabulary - Antonym":      "Antonym",
    "Vocabulary - Antonyms":     "Antonym",
    "Vocabulary (Antonyms)":     "Antonym",

    # ── Cloze Test ─────────────────────────────────────────────────────────────
    "Cloze Passage":               "Cloze Test",
    "Cloze Test (Passage-based)":  "Cloze Test",
    "Cloze Test (Single Filler)":  "Cloze Test",
    "Vocabulary (Cloze)":          "Cloze Test",

    # ── Fill in the Blanks ─────────────────────────────────────────────────────
    "Fill in the Blanks (Conjunction)":           "Fill in the Blanks",
    "Fill in the Blanks (Conjunctions)":          "Fill in the Blanks",
    "Fill in the Blanks (Grammar/Inversion)":     "Fill in the Blanks",
    "Fill in the Blanks (Grammar/Tense)":         "Fill in the Blanks",
    "Fill in the Blanks (Preposition)":           "Fill in the Blanks",
    "Fill in the Blanks (Prepositions/Connectors)":"Fill in the Blanks",
    "Fill in the Blanks (Question Word)":         "Fill in the Blanks",
    "Fill in the Blanks (Verb)":                  "Fill in the Blanks",
    "Grammar - Fill in the Blanks":               "Fill in the Blanks",
    "Vocabulary/Fill in the blank":               "Fill in the Blanks",
    "Double Fillers":                             "Fill in the Blanks",
    "Modals / Fill in the Blanks":                "Fill in the Blanks",
    "Conjunction Fill in the Blank":              "Fill in the Blanks",
    "Verb Fill in the Blank":                     "Fill in the Blanks",
    "Preposition Fill in the Blank":              "Fill in the Blanks",

    # ── Para Jumbles ───────────────────────────────────────────────────────────
    "Para Jumble":                       "Para Jumbles",
    "Para Jumbles (Sentence Completion)":"Para Jumbles",
    "Parajumbles":                       "Para Jumbles",
    "Grammar - Para Jumbles":            "Para Jumbles",
    "Ordering of Sentences (Para Jumble)":"Para Jumbles",

    # ── Sentence Rearrangement ─────────────────────────────────────────────────
    "Ordering of Words in a Sentence":     "Sentence Rearrangement",
    "Sentence Rearrangement (Word Jumble)":"Sentence Rearrangement",
    "Sentence Rearrangement (Word Order)": "Sentence Rearrangement",
    "Word Interchange":                    "Sentence Rearrangement",
    "Word Order":                          "Sentence Rearrangement",
    "Word Rearrangement":                  "Sentence Rearrangement",

    # ── Sentence Improvement ───────────────────────────────────────────────────
    "Sentence Improvement (Prepositions)":  "Sentence Improvement",
    "Vocabulary - Sentence Improvement":    "Sentence Improvement",
    "Vocabulary/Sentence Improvement":      "Sentence Improvement",
    "Phrase Replacement":                   "Sentence Improvement",

    # ── Sentence Completion ────────────────────────────────────────────────────
    "sentence completion":                 "Sentence Completion",
    "Sentence completion (Connectors)":    "Sentence Completion",
    "Sentence completion (Inversion)":     "Sentence Completion",
    "Sentence completion (Vocabulary)":    "Sentence Completion",
    "Sentence Completion (Column Matching)":"Sentence Completion",

    # ── Spelling ───────────────────────────────────────────────────────────────
    "Spelling Error":          "Spelling",
    "Spelling/Sentence Improvement": "Spelling",
    "Spelling/Usage Error":    "Spelling",
    "Misspelt Word":           "Spelling",
    "Vocabulary - Spelling":   "Spelling",

    # ── Phrasal Verbs ──────────────────────────────────────────────────────────
    "Phrasal Verb":                        "Phrasal Verbs",
    "Phrasal Verb Fill in the Blank":      "Phrasal Verbs",
    "Phrasal verbs":                       "Phrasal Verbs",
    "Phrasal Verbs / Fill in the Blanks":  "Phrasal Verbs",
    "Grammar - Phrasal Verbs":             "Phrasal Verbs",
    "Phrase Fill in the Blank":            "Phrasal Verbs",

    # ── Prepositions ───────────────────────────────────────────────────────────
    "Preposition":             "Prepositions",
    "Grammar - Preposition":   "Prepositions",
    "Grammar - Prepositions":  "Prepositions",

    # ── Homonyms / Homophones ──────────────────────────────────────────────────
    "Homonym":                           "Homonyms",
    "Homonyms/Confusing Words":          "Homonyms",
    "Word Usage (Homonym)":              "Homonyms",
    "Word Pairs":                        "Homonyms",
    "Vocabulary - Word Pairs / Confusables": "Homonyms",
    "Homophone":                         "Homophones",
    "Vocabulary - Homophones":           "Homophones",

    # ── Vocabulary (general) ───────────────────────────────────────────────────
    "Contextual Vocabulary Usage":       "Vocabulary",
    "Contextual Word Usage":             "Vocabulary",
    "General Vocabulary":                "Vocabulary",
    "Vocabulary (Contextual Usage)":     "Vocabulary",
    "Vocabulary (Word Meaning)":         "Vocabulary",
    "Vocabulary (Word Usage)":           "Vocabulary",
    "Vocabulary - Correct Word Usage":   "Vocabulary",
    "Vocabulary - Matching Word/Meaning":"Vocabulary",
    "Vocabulary - Vocabulary in Context":"Vocabulary",
    "Vocabulary in Context":             "Vocabulary",
    "Vocabulary/Collocation":            "Vocabulary",
    "Vocabulary (Passage-based)":        "Vocabulary",
    "Vocabulary (Word Usage)":           "Vocabulary",
    "Word Usage":                        "Vocabulary",
    "Collocation":                       "Vocabulary",
    "Collocations":                      "Vocabulary",
    "Verbal Analogy":                    "Vocabulary",
    "Word Usage":                        "Vocabulary",

    # ── Reading Comprehension ──────────────────────────────────────────────────
    "Reading Comprehension (Grammar-in-Context)":   "Reading Comprehension",
    "Reading Comprehension (Inference)":            "Reading Comprehension",
    "Reading Comprehension (Vocabulary in Context)":"Reading Comprehension",
    "Reading Comprehension (Vocabulary)":           "Reading Comprehension",
    "Reading Comprehension - Application":          "Reading Comprehension",
    "Reading Comprehension - Author's Purpose":     "Reading Comprehension",
    "Reading Comprehension - Author's Tone":        "Reading Comprehension",
    "Reading Comprehension - Character":            "Reading Comprehension",
    "Reading Comprehension - Detail":               "Reading Comprehension",
    "Reading Comprehension - Genre":                "Reading Comprehension",
    "Reading Comprehension - Grammar":              "Reading Comprehension",
    "Reading Comprehension - Idiom":                "Reading Comprehension",
    "Reading Comprehension - Inference":            "Reading Comprehension",
    "Reading Comprehension - Interpretation":       "Reading Comprehension",
    "Reading Comprehension - Main Idea":            "Reading Comprehension",
    "Reading Comprehension - Vocabulary":           "Reading Comprehension",
    "Reading Comprehension - Vocabulary/Inference": "Reading Comprehension",

    # ── Grammar (general) ──────────────────────────────────────────────────────
    "Grammar (Adverbs)":                    "Grammar",
    "Grammar (Articles)":                   "Grammar",
    "Grammar (Comparatives)":               "Grammar",
    "Grammar (Conditionals)":               "Grammar",
    "Grammar (Conjunctions)":               "Grammar",
    "Grammar (Subject-Verb Agreement)":     "Grammar",
    "Grammar (Tense)":                      "Grammar",
    "Grammar (Verb Forms)":                 "Grammar",
    "Grammar - Articles":                   "Grammar",
    "Grammar - Conjunctions":               "Grammar",
    "Grammar - Determiners":                "Grammar",
    "Grammar - Discourse Markers":          "Grammar",
    "Grammar - Parts of Speech Identification": "Grammar",
    "Grammar - Question Formation":         "Grammar",
    "Grammar - Question Tags":              "Grammar",
    "Grammar - Sentence Formation":         "Grammar",
    "Grammar - Subject-Verb Agreement":     "Grammar",
    "Grammar - Tenses":                     "Grammar",
    "Grammar - Word Forms / Parts of Speech": "Grammar",
    "Adjective Order":                      "Grammar",
    "Adverbs":                              "Grammar",
    "Articles":                             "Grammar",
    "Conditionals":                         "Grammar",
    "Conjunction":                          "Grammar",
    "Discourse Markers":                    "Grammar",
    "Figure of Speech":                     "Grammar",
    "Pronoun-Antecedent Agreement":         "Grammar",
    "Pronouns":                             "Grammar",
    "Punctuation":                          "Grammar",
    "Question Tags":                        "Grammar",
    "Relative pronouns":                    "Grammar",
    "Subject-verb agreement":               "Grammar",
    "Subject-Verb Agreement":               "Grammar",
    "Subjunctive mood":                     "Grammar",
    "Tenses":                               "Grammar",
}


def normalize_file(filepath: Path) -> tuple[int, int]:
    data = json.loads(filepath.read_text(encoding="utf-8-sig"))
    changed = 0
    for entry in data:
        old = entry.get("topic", "").strip()
        new = TOPIC_MAP.get(old, old)
        if new != old:
            entry["topic"] = new
            changed += 1
    filepath.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return len(data), changed


if __name__ == "__main__":
    print("Normalizing PYQ topics...\n")
    total_changed = 0
    for f in sorted(BASE.glob("pyq_*.json")):
        count, changed = normalize_file(f)
        total_changed += changed
        print(f"  {f.name:35s}  {count:4d} entries  {changed:3d} updated")
    print(f"\nTotal entries updated: {total_changed}")
