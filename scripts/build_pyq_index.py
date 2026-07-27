"""
Build word → PYQ index.
Output: assets/data/pyq_word_index.json
  { "perfidious": [{"exam":"SSC CGL","year":"2025","file":"pyq_ssc","idx":42}] }
"""

import json
import re
from pathlib import Path

BASE   = Path(__file__).parent.parent / "assets" / "data"
OUTPUT = BASE / "pyq_word_index.json"

LEARN_FILES = {
    "synonyms":  BASE / "synonyms.json",
    "antonyms":  BASE / "synonyms.json",   # antonyms live in same file
    "one_word":  BASE / "one_word.json",
    "idioms":    BASE / "idioms.json",
    "voices":    BASE / "voices.json",
    "narration": BASE / "narration.json",
    "core":      BASE / "core_words.json",
    "advanced":  BASE / "advanced.json",
}

# Common words that appear everywhere in question text — not useful as match keys
STOPWORDS = {
    "meaning", "select", "correct", "answer", "option", "sentence", "word",
    "following", "given", "most", "appropriate", "choose", "find", "identify",
    "fill", "blank", "part", "error", "passage", "question", "statement",
    "complete", "improve", "rearrange", "indicate", "underline", "bold",
    "change", "express", "follow", "accept", "opportunity", "provide",
    "suggest", "describe", "explain", "indicate", "represent", "include",
    "contain", "refer", "relate", "associate", "connect", "combine",
    "a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "may", "might", "must", "shall", "can", "need", "dare",
}


def load_vocab():
    """Return {word_lower: word_original} for all learn categories."""
    words = {}
    for cat, path in LEARN_FILES.items():
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        for entry in data:
            w = entry.get("word", "").strip()
            if w:
                words[w.lower()] = w
            # also index synonyms list for cross-matching
            for s in entry.get("synonyms", []):
                s = s.strip()
                if s:
                    words[s.lower()] = s
    return words


def extract_target(question: str) -> str:
    """Extract the target word from 'synonym/antonym of: WORD' style questions."""
    if ":" in question:
        candidate = question.split(":")[-1].strip().rstrip(".?,;").strip()
        # Remove any trailing parenthetical
        candidate = re.sub(r"\(.*\)$", "", candidate).strip()
        return candidate.lower()
    return ""


def build_index(vocab_words: dict) -> dict:
    index = {}  # word_lower → list of {exam, year, file, idx}

    for pyq_path in sorted(BASE.glob("pyq_*.json")):
        file_key = pyq_path.stem  # e.g. "pyq_ssc"
        data = json.loads(pyq_path.read_text(encoding="utf-8-sig"))

        for idx, q in enumerate(data):
            if not isinstance(q, dict):
                continue
            question  = q.get("question", "")
            options   = q.get("options", [])
            correct   = q.get("correct_answer", "").strip()
            topic     = q.get("topic", "")
            exam      = q.get("exam", "")
            year      = q.get("year", "")

            entry = {"exam": exam, "year": year, "file": file_key, "idx": idx}

            matched = set()

            # 1. Synonym / Antonym / Vocabulary — strict: word extracted after colon
            target = extract_target(question)
            if (target
                    and len(target) >= 4
                    and target not in STOPWORDS
                    and target in vocab_words):
                matched.add(target)

            # 2. One Word Substitution — correct answer IS the one-word
            if topic == "One Word Substitution":
                c = correct.lower()
                if c and c not in STOPWORDS and len(c) >= 4 and c in vocab_words:
                    matched.add(c)

            # 3. Idioms — idiom phrase (≥3 words) appears in question/options
            if topic == "Idioms & Phrases":
                all_text = (question + " " + " ".join(options)).lower()
                for word_l in vocab_words:
                    if (len(word_l.split()) >= 3
                            and word_l not in STOPWORDS
                            and word_l in all_text):
                        matched.add(word_l)

            # 4. Voice / Narration — full source sentence appears in question
            if topic in ("Voice Change", "Narration"):
                q_lower = question.lower()
                for word_l in vocab_words:
                    if (len(word_l.split()) >= 5
                            and word_l in q_lower):
                        matched.add(word_l)

            for word_l in matched:
                index.setdefault(word_l, []).append(entry)

    # Deduplicate: keep one entry per (exam, year) pair per word
    deduped = {}
    for word, entries in index.items():
        seen = set()
        unique = []
        for e in entries:
            key = (e["exam"], e["year"])
            if key not in seen:
                seen.add(key)
                unique.append(e)
        deduped[word] = unique

    return deduped


if __name__ == "__main__":
    print("Loading vocab words...")
    vocab = load_vocab()
    print(f"  {len(vocab)} unique words/phrases loaded")

    print("Building PYQ index...")
    index = build_index(vocab)
    print(f"  {len(index)} words matched to PYQs")

    OUTPUT.write_text(
        json.dumps(index, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"  Written to {OUTPUT}")

    # Stats
    total_links = sum(len(v) for v in index.values())
    print(f"  Total word→PYQ links: {total_links}")
    print("\nTop 10 most-asked words:")
    for w, entries in sorted(index.items(), key=lambda x: -len(x[1]))[:10]:
        exams = ", ".join(f"{e['exam']} {e['year']}" for e in entries[:3])
        print(f"  {w:20s}  {len(entries)} exams  [{exams}]")
