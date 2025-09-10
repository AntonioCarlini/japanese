  #!/usr/bin/env python3

import argparse
import yaml
import pykakasi


def load_yaml(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def sort_words(words):
    kakasi = pykakasi.kakasi()

    def sort_key(word: str) -> str:
        # Convert to kana for consistent 五十音 order
        result = kakasi.convert(word)
        return "".join([item["kana"] for item in result])

    return sorted(words, key=sort_key)


def build_html(data: dict) -> str:
    html = []
    html.append("<html>")
    html.append("<head>")
    html.append("<meta charset='utf-8'>")
    html.append("<title>Onomatopoeia</title>")
    html.append(
        """
<style>
table { border-collapse: collapse; width: 90%; }
td, th { border: 1px solid #aaa; padding: 4px; }
td:first-child {
  white-space: nowrap;
  width: 1%;
  padding: 0 0.5em; /* left/right padding for the word column */
}

td:nth-child(2) {
  text-align: center;
  width: 3ch;        /* fixed width ~3 characters */
  padding: 0 0.25em; /* some breathing room */
}
.hidden { display: none; }
</style>
<script>
function toggle(id) {
  var e = document.getElementById(id);
  if (e.classList.contains('hidden')) {
    e.classList.remove('hidden');
  } else {
    e.classList.add('hidden');
  }
}
</script>
"""
    )
    html.append("</head>")
    html.append("<body>")

    html.append("<table>")
    html.append("<tr><th>Word</th><th>Category</th><th>Sentences</th></tr>")

    for i, word in enumerate(sort_words(data.keys())):
        entry = data[word]
        # normalise to a list for uniform processing
        if isinstance(entry, dict):
            entries = [entry]
        elif isinstance(entry, list):
            entries = entry
        else:
            raise TypeError(f"Unexpected type for {word}: {type(entry)}")

        for cat_entry in entries:
            category = cat_entry.get("category", "")
            definition = cat_entry.get("definition", "")
            sentences = cat_entry.get("sentences", []) or []

            # build keyword label
            if len(entries) > 1:
                keyword = f"{word} ({category})"
            else:
                keyword = word

            def_id = f"def_{i}"
            sen_id = f"sen_{i}"

            # Row for the word
            html.append("<tr>")
            definition = cat_entry.get('definition')

            # Word
            html.append(f"<tr><td><span title='{definition}'>{keyword}</span></td>")

            # Category (currently empty)
            html.append(f"<td></td>")
            
            sentence_texts = "<br>".join(
              [f'<span title="{s["english"]}">{s["jp"].replace(word, f"<b>{word}</b>")}</span>' for s in sentences]
            )

            html.append(
                f"<td><a href='#' onclick=\"toggle('{sen_id}');return false;\">S</a>"
                f"<div id='{sen_id}' class='hidden'>{sentence_texts}</div></td>"
            )
            html.append("</tr>")

    html.append("</table>")
    html.append("</body></html>")
    return "\n".join(html)


def main():
    parser = argparse.ArgumentParser(
        description="Build onomatopoeia HTML page from YAML"
    )
    parser.add_argument("input", help="Input YAML file")
    parser.add_argument("output", help="Output HTML file")
    args = parser.parse_args()

    data = load_yaml(args.input)
    html = build_html(data)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)


if __name__ == "__main__":
    main()
    
