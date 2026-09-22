"""
Expand learn content files using PYQ data.
Targets: voices.json, narration.json, idioms.json, one_word.json, synonyms.json
"""

import json
import re
import os
from pathlib import Path

BASE = Path(__file__).parent.parent / "assets" / "data"

# ── helpers ──────────────────────────────────────────────────────────────────

def load(filename):
    with open(BASE / filename, encoding="utf-8") as f:
        return json.load(f)

def save(filename, data):
    with open(BASE / filename, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  Saved {filename} ({len(data)} entries)")

def load_all_pyq():
    entries = []
    for f in BASE.glob("pyq_*.json"):
        try:
            data = json.loads(f.read_text(encoding="utf-8-sig"))
            for item in data:
                item["_source"] = f.name
            entries.extend(data)
        except Exception as e:
            print(f"  Skip {f.name}: {e}")
    print(f"Loaded {len(entries)} total PYQ entries")
    return entries

def extract_after_colon(text):
    """Extract content after the last colon or newline."""
    text = text.strip()
    # Try newline split first
    if "\n" in text:
        last = text.split("\n")[-1].strip()
        if len(last) > 10:
            return last.strip('"').strip("'").strip()
    # Try colon
    if ":" in text:
        after = text.split(":", 1)[1].strip()
        # Make sure it's a full sentence, not just "passive" etc.
        if len(after) > 10:
            return after.strip('"').strip("'").strip()
    return ""

def extract_quoted(text):
    """Extract first quoted phrase from text."""
    m = re.search(r'["“‘]([^"”’]{3,})["”’]', text)
    if m:
        return m.group(1).strip()
    # fallback: after last colon on last line
    lines = [l.strip() for l in text.strip().split("\n") if l.strip()]
    if lines:
        last = lines[-1]
        if ":" in last:
            after = last.split(":")[-1].strip().strip('"').strip("'")
            if len(after) > 2:
                return after
        return last.strip('"').strip("'")
    return ""

# ── 1. VOICES ────────────────────────────────────────────────────────────────

VOICE_TOPICS = {
    "Voice (Active-Passive)", "Active and Passive Voice", "Voice Change",
    "Active-Passive Voice", "Active/Passive Voice", "Grammar (Passive Voice)",
    "Grammar - Voice Change",
}

def expand_voices(pyq_all):
    print("\n[1] Expanding voices.json ...")
    existing = load("voices.json")
    existing_words = {e["word"].strip().lower() for e in existing}

    voice_pyqs = [p for p in pyq_all if p.get("topic", "") in VOICE_TOPICS]
    print(f"  PYQ voice entries: {len(voice_pyqs)}")

    new_entries = []
    for p in voice_pyqs:
        q = p.get("question", "")
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()
        options = p.get("options", [])

        # Extract the source sentence from the question
        sentence = extract_after_colon(q)
        if not sentence or len(sentence) < 10:
            continue
        if not answer or len(answer) < 10:
            continue
        # Skip if active sentence already exists
        if sentence.strip().lower() in existing_words:
            continue

        entry = {
            "word": sentence,
            "meaning_en": explanation,
            "meaning_hi": "",
            "example": answer,
            "options": options if options else [answer],
            "synonyms": [],
            "antonyms": [],
            "category": "voices",
        }
        new_entries.append(entry)
        existing_words.add(sentence.strip().lower())

    print(f"  New entries to add: {len(new_entries)}")
    combined = existing + new_entries
    save("voices.json", combined)
    return len(new_entries)

# ── 2. NARRATION ─────────────────────────────────────────────────────────────

NARRATION_TOPICS = {
    "Narration", "Direct-Indirect Speech", "Narration (Direct-Indirect)",
    "Narration (Direct/Indirect Speech)", "Narration (Direct-Indirect Speech)",
    "Grammar - Narration (Direct-Indirect Speech)", "Direct/Indirect Speech",
    "Direct and Indirect Speech",
}

def expand_narration(pyq_all):
    print("\n[2] Expanding narration.json ...")
    existing = load("narration.json")
    existing_words = {e["word"].strip().lower() for e in existing}

    narr_pyqs = [p for p in pyq_all if p.get("topic", "") in NARRATION_TOPICS]
    print(f"  PYQ narration entries: {len(narr_pyqs)}")

    new_entries = []
    for p in narr_pyqs:
        q = p.get("question", "")
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()
        options = p.get("options", [])

        sentence = extract_after_colon(q)
        if not sentence or len(sentence) < 10:
            continue
        if not answer or len(answer) < 10:
            continue
        if sentence.strip().lower() in existing_words:
            continue

        # Must look like direct speech (has quotes) or indirect question
        has_quote = any(c in sentence for c in ['"', "'", "“", "‘"])
        is_indirect = any(w in q.lower() for w in ["direct", "indirect", "reported", "narration"])
        if not (has_quote or is_indirect):
            continue

        entry = {
            "word": sentence,
            "meaning_en": explanation,
            "meaning_hi": "",
            "example": answer,
            "options": options if options else [answer],
            "synonyms": [],
            "antonyms": [],
            "category": "narration",
        }
        new_entries.append(entry)
        existing_words.add(sentence.strip().lower())

    print(f"  New entries to add: {len(new_entries)}")
    combined = existing + new_entries
    save("narration.json", combined)
    return len(new_entries)

# ── 3. IDIOMS ────────────────────────────────────────────────────────────────

IDIOM_TOPICS = {
    "Idiom", "Idioms", "Idioms and Phrases", "Idioms & Phrases",
    "Idiom Meaning", "Idioms and Proverbs", "Vocabulary - Idioms",
    "Idiom Fill in the Blank", "Idiom (Passage-based)",
}

def expand_idioms(pyq_all):
    print("\n[3] Expanding idioms.json ...")
    existing = load("idioms.json")
    existing_words = {e["word"].strip().lower() for e in existing}

    idiom_pyqs = [p for p in pyq_all if p.get("topic", "") in IDIOM_TOPICS]
    print(f"  PYQ idiom entries: {len(idiom_pyqs)}")

    new_entries = []
    for p in idiom_pyqs:
        q = p.get("question", "")
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()

        idiom_name = extract_quoted(q)
        if not idiom_name or len(idiom_name) < 4:
            continue
        # Skip if just a fill-in-the-blank sentence (contains ___ or blank)
        if any(w in q.lower() for w in ["____", "blank", "fill in"]):
            continue
        if idiom_name.strip().lower() in existing_words:
            continue
        if not answer:
            continue

        # Use explanation as meaning_en if it's richer, else use answer
        meaning = explanation if len(explanation) > len(answer) else answer

        entry = {
            "word": idiom_name,
            "meaning_en": meaning,
            "meaning_hi": "",
            "example": "",
            "synonyms": [],
            "antonyms": [],
            "category": "idioms",
        }
        new_entries.append(entry)
        existing_words.add(idiom_name.strip().lower())

    print(f"  New entries to add: {len(new_entries)}")
    combined = existing + new_entries
    save("idioms.json", combined)
    return len(new_entries)

# ── 4. ONE WORD SUBSTITUTION ─────────────────────────────────────────────────

OW_TOPICS = {
    "One Word Substitution", "One-word substitution",
    "Vocabulary - One Word Substitution", "Vocabulary (One-word Substitution)",
}

def extract_ow_definition(q):
    """Extract the phrase/definition for one-word substitution."""
    q = q.strip()
    # Remove common prefixes
    prefixes = [
        r"select the option that can be used as a one.word substitute for the given (?:group of )?words?[:\.\n]+",
        r"choose from the four options, the word that best defines?/substitutes? the given phrase[:\.\n]+",
        r"choose the one.word substitute for[:\.\n]+",
        r"select the one.word substitute[:\.\n]+",
        r"given below is a (?:group of )?words?[:\.\n]+",
        r"[^\n]+\n",  # fallback: take after first line
    ]
    for pattern in prefixes:
        m = re.sub(pattern, "", q, flags=re.IGNORECASE)
        m = m.strip()
        if m and len(m) > 5 and m != q.strip():
            return m.strip().rstrip(".")
    # Last resort: take last line
    lines = [l.strip() for l in q.split("\n") if l.strip()]
    return lines[-1].rstrip(".") if lines else ""

def expand_oneword(pyq_all):
    print("\n[4] Expanding one_word.json ...")
    existing = load("one_word.json")
    existing_words = {e["word"].strip().lower() for e in existing}
    existing_meanings = {e.get("meaning_en", "").strip().lower() for e in existing}

    ow_pyqs = [p for p in pyq_all if p.get("topic", "") in OW_TOPICS]
    print(f"  PYQ one-word entries: {len(ow_pyqs)}")

    new_entries = []
    for p in ow_pyqs:
        q = p.get("question", "")
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()

        if not answer:
            continue
        definition = extract_ow_definition(q)
        if not definition or len(definition) < 5:
            continue

        # Skip if word OR definition already exists
        if answer.strip().lower() in existing_words:
            continue
        if definition.strip().lower() in existing_meanings:
            continue

        entry = {
            "word": answer,
            "meaning_en": definition,
            "meaning_hi": "",
            "example": "",
            "synonyms": [],
            "antonyms": [],
            "category": "oneword",
        }
        new_entries.append(entry)
        existing_words.add(answer.strip().lower())
        existing_meanings.add(definition.strip().lower())

    print(f"  New entries to add: {len(new_entries)}")
    combined = existing + new_entries
    save("one_word.json", combined)
    return len(new_entries)

# ── 5. SYNONYMS/ANTONYMS ─────────────────────────────────────────────────────

SYN_TOPICS = {
    "Synonym", "Synonyms", "Vocabulary - Synonym", "Vocabulary (Synonyms)",
    "Vocabulary (Word Meaning)", "Vocabulary", "Vocabulary - Vocabulary in Context",
}
ANT_TOPICS = {
    "Antonym", "Antonyms", "Vocabulary - Antonym", "Vocabulary (Antonyms)",
}

def extract_target_word(q):
    """Extract the target word from a synonym/antonym question."""
    # Pattern: "...of the given word: WORD" or "...of the word: WORD"
    m = re.search(r'(?:given word|the word)[:\s]+["“]?([A-Z][A-Z\s\-\']+)["”]?', q)
    if m:
        return m.group(1).strip().title()
    # Pattern: quoted word
    m = re.search(r'["“]([A-Za-z\s\-\']{2,30})["”]', q)
    if m:
        return m.group(1).strip().title()
    # Last line if it looks like a word
    lines = [l.strip() for l in q.split("\n") if l.strip()]
    if lines:
        last = lines[-1].strip('"').strip("'").strip()
        if re.match(r'^[A-Za-z\-\s]{2,25}$', last) and last.isupper():
            return last.title()
    return ""

def expand_synonyms(pyq_all):
    print("\n[5] Expanding synonyms.json ...")
    existing = load("synonyms.json")
    existing_map = {e["word"].strip().lower(): e for e in existing}

    syn_pyqs = [p for p in pyq_all if p.get("topic", "") in SYN_TOPICS]
    ant_pyqs = [p for p in pyq_all if p.get("topic", "") in ANT_TOPICS]
    print(f"  PYQ synonym entries: {len(syn_pyqs)}, antonym entries: {len(ant_pyqs)}")

    # Build a dict of word → {synonyms: set, antonyms: set, meaning: str}
    word_data = {}

    for p in syn_pyqs:
        word = extract_target_word(p.get("question", ""))
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()
        if not word or not answer:
            continue
        key = word.lower()
        if key not in word_data:
            word_data[key] = {"word": word, "synonyms": set(), "antonyms": set(), "meaning": explanation}
        word_data[key]["synonyms"].add(answer)

    for p in ant_pyqs:
        word = extract_target_word(p.get("question", ""))
        answer = p.get("correct_answer", "").strip()
        explanation = p.get("explanation", "").strip()
        if not word or not answer:
            continue
        key = word.lower()
        if key not in word_data:
            word_data[key] = {"word": word, "synonyms": set(), "antonyms": set(), "meaning": explanation}
        word_data[key]["antonyms"].add(answer)

    new_count = 0
    updated_count = 0

    for key, data in word_data.items():
        if key in existing_map:
            # Update existing entry with any new synonyms/antonyms
            entry = existing_map[key]
            existing_syn = set(entry.get("synonyms", []))
            existing_ant = set(entry.get("antonyms", []))
            new_syn = data["synonyms"] - existing_syn
            new_ant = data["antonyms"] - existing_ant
            if new_syn or new_ant:
                entry["synonyms"] = sorted(existing_syn | data["synonyms"])
                entry["antonyms"] = sorted(existing_ant | data["antonyms"])
                updated_count += 1
        else:
            # New word — add it
            new_entry = {
                "word": data["word"],
                "meaning_en": data["meaning"],
                "meaning_hi": "",
                "example": "",
                "synonyms": sorted(data["synonyms"]),
                "antonyms": sorted(data["antonyms"]),
                "category": "synonyms",
            }
            existing_map[key] = new_entry
            new_count += 1

    print(f"  New words added: {new_count}, existing words enriched: {updated_count}")
    combined = list(existing_map.values())
    save("synonyms.json", combined)
    return new_count

# ── MAIN ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("Vocabo Content Expansion Script")
    print("=" * 60)

    pyq_all = load_all_pyq()

    totals = {}
    totals["voices"]    = expand_voices(pyq_all)
    totals["narration"] = expand_narration(pyq_all)
    totals["idioms"]    = expand_idioms(pyq_all)
    totals["one_word"]  = expand_oneword(pyq_all)
    totals["synonyms"]  = expand_synonyms(pyq_all)

    print("\n" + "=" * 60)
    print("SUMMARY — new entries added:")
    for k, v in totals.items():
        print(f"  {k:25s} +{v}")
    print("=" * 60)
