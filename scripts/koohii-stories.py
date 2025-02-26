"""
This script processes a CSV file of kanji stories from https://kanji.koohii.com/ and generates an HTML table.
The table includes the following columns:
1. Heisig Kanji Index (1-3000)
2. Heisig Keyword (or "MISSING" if the entry is missing)
3. Kanji (formatted as @KJ{{KEYWORD}})
4. Story
5. Referenced Kanji/Parts (kanji and parts used to build this kanji)
6. Kanji Using This Kanji (kanji that reference this kanji in their stories)

The script handles missing entries, duplicate keywords, and references to other kanji or frame numbers within stories.
"""

import csv
import sys
from collections import defaultdict

# Constants
KANJI_MAX_FRAME_NUMBER = 3000
REPORT_NON_HEISIG_KANJI = False  # Set to True to report non-Heisig kanji
DISPLAY_FRAME_NUMBER_MAP = False  # Set to True to display the frame number map

class Entry:
    def __init__(self, frame_number, kanji, heisig_keyword, story):
        self.frame_number = frame_number                    # Heisig frame number
        self.kanji = kanji                                  # the kanji, as a unicode character
        self.heisig_keyword = heisig_keyword                # Heisig keyword (on my login on koohii.com)
        self.story = story                                  # My story associated with the kanji

def parse_csv(file_name):
    entries = []
    heisig_keyword_map = {}
    frame_number_map = defaultdict(list)
    missing_kanji_map = defaultdict(set)
    keyword_count = defaultdict(int)
    frame_to_kanji = {}  # Maps frame numbers to kanji
    kanji_to_frame = {}  # Maps kanji to frame numbers

    # First pass: Build the frame_to_kanji and kanji_to_frame maps
    with open(file_name, mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        header_skipped = False

        for row in reader:
            # Skip header if the first field is not an integer
            if not header_skipped and not row[0].isdigit():
                header_skipped = True
                continue

            try:
                frame_number = int(row[0])
            except ValueError:
                continue  # Skip invalid frame numbers

            kanji = row[1]
            frame_to_kanji[frame_number] = kanji
            kanji_to_frame[kanji] = frame_number

    # Second pass: Process entries and resolve references
    with open(file_name, mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        header_skipped = False

        for line_number, row in enumerate(reader, start=1):
            # Skip header if the first field is not an integer
            if not header_skipped and not row[0].isdigit():
                header_skipped = True
                continue

            try:
                frame_number = int(row[0])
            except ValueError:
                print(f"ERROR: Line {line_number} - Frame number '{row[0]}' is not a valid integer.")
                continue

            kanji = row[1]
            heisig_keyword = row[2]
            story = row[5]

            # Handle duplicate keywords
            if heisig_keyword in keyword_count:
                if frame_number <= KANJI_MAX_FRAME_NUMBER:
                    keyword_count[heisig_keyword] += 1
                    new_keyword = f"{heisig_keyword}-DUP-{keyword_count[heisig_keyword]:04d}"
                    print(f"WARNING: Duplicate keyword '{heisig_keyword}' found on line {line_number}. Using '{new_keyword}' instead.")
                    heisig_keyword = new_keyword
                else:
                    # Ignore duplicates in the non-kanji range
                    continue
            else:
                keyword_count[heisig_keyword] = 1

            # Add to heisig_keyword_map
            heisig_keyword_map[frame_number] = Entry(frame_number, kanji, heisig_keyword, story)

            # Create Entry object
            entry = Entry(frame_number, kanji, heisig_keyword, story)
            entries.append(entry)

            # Parse story for referenced kanji or frame numbers
            referenced_kanji_or_frames = set()
            start = story.find('{')
            while start != -1:
                end = story.find('}', start)
                if end == -1:
                    break
                content = story[start + 1:end]
                referenced_kanji_or_frames.add(content)
                start = story.find('{', end + 1)

            # Process referenced kanji or frame numbers
            for ref in referenced_kanji_or_frames:
                if ref.isdigit():
                    # Handle frame number references (e.g., {908})
                    ref_frame = int(ref)
                    if ref_frame in frame_to_kanji:
                        ref_kanji = frame_to_kanji[ref_frame]
                        if ref_frame <= KANJI_MAX_FRAME_NUMBER:
                            frame_number_map[ref_frame].append(frame_number)
                        else:
                            # Ignore references to non-Heisig kanji
                            continue
                    else:
                        if ref_frame <= KANJI_MAX_FRAME_NUMBER:
                            print(f"FRAME NUMBER WITHOUT KANJI: Frame '{ref_frame}' referenced in frame {frame_number}.")
                        continue
                else:
                    # Handle kanji references (e.g., {古})
                    ref_kanji = ref
                    ref_frame = kanji_to_frame.get(ref_kanji)

                if ref_frame is not None:
                    if ref_frame <= KANJI_MAX_FRAME_NUMBER:
                        frame_number_map[ref_frame].append(frame_number)
                else:
                    if REPORT_NON_HEISIG_KANJI:
                        missing_kanji_map[ref_kanji].add(frame_number)

    return entries, heisig_keyword_map, frame_number_map, missing_kanji_map, kanji_to_frame

def format_story(story, current_keyword, heisig_keyword_map, kanji_to_frame):
    """
    Formats the story by applying the following rules:
    - #text# becomes <b>text</b> (bold).
    - (*{kanji}*) becomes (@KJ{{keyword}}) (italic, hyperlinked, and wrapped in parentheses).
    - The current keyword in the story (not already bold) is made bold (case-insensitive match, retain original case).

     The *...* => <i> ...</i> formatting is problematic as '*' may appear in 
       (1) kanji names (e.g. "olden*times")
       (2) and also in (*{kanji}*).
     So if the *...* swap is done before the kanji processing then it will modfiy the string in case (2), which will break kanji processing.
     If instead the *...* swap is done before the kanji processing then it will modfiy the string in case (1), which will mangle the kanji name
     and that will break subsequent processing (performed by another script).
     So during kanji processing, any space in a kanji name that needs to become a '*', becomes a short-term string instead (which has no '*' in it).
     Then, towards the end, the *...* substitution can be safely made.
     After that the short-term string is swapped back to '*'.
     the only requirement is that the short-term string does not appear in any story and that can be empirically checked with a simple grep.
    """
    import re

    short_term_swap = "~|~"
    
    # Replace #text# with <b>text</b>
    story = re.sub(r"#([^#]+?)#", r"<b>\1</b>", story)

    # Replace (*{kanji}*) with (@KJ{{keyword}}) or (<i>kanji</i>)
    def replace_kanji(match):
        kanji = match.group(1)
        frame_number = kanji_to_frame.get(kanji)
        if frame_number is not None and frame_number in heisig_keyword_map:
            keyword = heisig_keyword_map[frame_number].heisig_keyword
            # Replace spaces with asterisks in the keyword
            formatted_keyword = keyword.replace(" ", short_term_swap)
            return f"(<i><a href='#{frame_number}'>@KJ{{{{{formatted_keyword}}}}}</a></i>)"
        else:
            return f"(<i>{kanji}</i>)"

    # Handle (*{kanji}*)
    story = re.sub(r"\(\*\{([^{}]+)\}\*\)", replace_kanji, story)

    # Make the current keyword bold (if not already bold)
    if current_keyword:
        # Case-insensitive match, but retain original case in the story
        story = re.sub(
            rf"\b{re.escape(current_keyword)}\b",
            lambda match: f"<b>{match.group(0)}</b>",
            story,
            flags=re.IGNORECASE,
        )

    # Replace *text* with <i>text</i>
    story = re.sub(r"\*([^*]+?)\*", r"<i>\1</i>", story)

    story = story.replace(short_term_swap, "*")

    return story

def generate_html_table(entries, heisig_keyword_map, frame_number_map, missing_kanji_map, kanji_to_frame, output_file):
    """
    Generates an HTML table from the parsed entries and writes it to a file or stdout.
    """
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Kanji Stories</title>
        <style>
            table {
                width: 100%;
                border-collapse: collapse;
            }
            th, td {
                border: 1px solid black;
                padding: 8px;
                text-align: left;
            }
            th {
                background-color: #f2f2f2;
            }
            a {
                text-decoration: none;
                color: #0366d6;
            }
            a:hover {
                text-decoration: underline;
            }
            .col1 { width: 6em; }
            .col2 { width: 12em; }
            .col3 { width: 2em; }
            .col4 { width: 35%; }
            td:nth-child(3) { font-size: 16pt; }

        </style>
    </head>
    <body>
        <h1>Kanji Stories (1-3000)</h1>
        <table>
            <colgroup>
                <col class="col1">
                <col class="col2">
                <col class="col3">
                <col class="col4">
                <col class="col5">
                <col class="col6">
            </colgroup>
            <tr>
                <th>Heisig Index</th>
                <th>Keyword</th>
                <th>Kanji</th>
                <th>Story</th>
                <th>Referenced Kanji/Parts</th>
                <th>Kanji Using This Kanji</th>
            </tr>
    """

    # Generate table rows for frame numbers 1-3000
    for frame_number in range(1, KANJI_MAX_FRAME_NUMBER + 1):
        entry = heisig_keyword_map.get(frame_number)
        if entry:
            keyword = entry.heisig_keyword
            formatted_keyword = keyword.replace(" ", "*")
            kanji = f"@KJ{{{{{formatted_keyword}}}}}"
            story = format_story(entry.story, entry.heisig_keyword, heisig_keyword_map, kanji_to_frame)

            # Column 5: Referenced Kanji/Parts
            referenced_parts = set()
            start = story.find('{')
            while start != -1:
                end = story.find('}', start)
                if end == -1:
                    break
                content = story[start + 1:end]
                if content.isdigit():
                    ref_frame = int(content)
                    if ref_frame in heisig_keyword_map:
                        ref_entry = heisig_keyword_map[ref_frame]
                        ref_keyword = ref_entry.heisig_keyword
                        if ref_keyword.lower() != "darken":
                            formatted_ref_keyword = ref_keyword.replace(" ", "*")
                            referenced_parts.add(f"<a href='#{ref_frame}'>@KJ{{{{{formatted_ref_keyword}}}}}</a>")
                else:
                    ref_frame = kanji_to_frame.get(content)
                    if ref_frame is not None and ref_frame in heisig_keyword_map:
                        ref_entry = heisig_keyword_map.get(ref_frame)
                        if ref_entry:
                            ref_keyword = ref_entry.heisig_keyword
                            if ref_keyword.lower() != "darken":
                                formatted_ref_keyword = ref_keyword.replace(" ", "*")
                                referenced_parts.add(f"<a href='#{ref_frame}'>@KJ{{{{{formatted_ref_keyword}}}}}</a>")
                start = story.find('{', end + 1)

            referenced_parts_str = ", ".join(sorted(referenced_parts))

            # Column 6: Kanji Using This Kanji
            using_kanji = frame_number_map.get(frame_number, [])
            using_kanji_str = ", ".join(
                f"<a href='#{ref_frame}'>@KJ{{{{{heisig_keyword_map[ref_frame].heisig_keyword.replace(' ', '*')}}}}}</a>"
                for ref_frame in sorted(using_kanji)
                if ref_frame in heisig_keyword_map and heisig_keyword_map[ref_frame].heisig_keyword.lower() != "darken"
            )
        else:
            keyword = "MISSING"
            kanji = ""
            story = ""
            referenced_parts_str = ""
            using_kanji_str = ""

        html_content += f"""
        <tr id="{frame_number}">
            <td>{frame_number}</td>
            <td>{keyword}</td>
            <td>{kanji}</td>
            <td>{story}</td>
            <td>{referenced_parts_str}</td>
            <td>{using_kanji_str}</td>
        </tr>
        """

    # Add the second table for frame numbers > 3000 (only for entries that exist in the input data)
    html_content += """
        </table>
        <h1>Non-Kanji Stories (3001+)</h1>
        <table>
            <colgroup>
                <col class="col1">
                <col class="col2">
                <col class="col3">
                <col class="col4">
                <col class="col5">
                <col class="col6">
            </colgroup>
            <tr>
                <th>Heisig Index</th>
                <th>Keyword</th>
                <th>Kanji</th>
                <th>Story</th>
                <th>Referenced Kanji/Parts</th>
                <th>Kanji Using This Kanji</th>
            </tr>
    """

    # Only generate rows for frame numbers that exist in heisig_keyword_map
    for frame_number in sorted(heisig_keyword_map.keys()):
        if frame_number > KANJI_MAX_FRAME_NUMBER:
            entry = heisig_keyword_map.get(frame_number)
            if entry:
                keyword = entry.heisig_keyword
                formatted_keyword = keyword.replace(" ", "*")
                kanji = f"@KJ{{{{{formatted_keyword}}}}}"
                story = format_story(entry.story, entry.heisig_keyword, heisig_keyword_map, kanji_to_frame)

                # Column 5: Referenced Kanji/Parts
                referenced_parts = set()
                start = story.find('{')
                while start != -1:
                    end = story.find('}', start)
                    if end == -1:
                        break
                    content = story[start + 1:end]
                    if content.isdigit():
                        ref_frame = int(content)
                        if ref_frame in heisig_keyword_map:
                            ref_entry = heisig_keyword_map[ref_frame]
                            ref_keyword = ref_entry.heisig_keyword
                            if ref_keyword.lower() != "darken":
                                formatted_ref_keyword = ref_keyword.replace(" ", "*")
                                referenced_parts.add(f"<a href='#{ref_frame}'>@KJ{{{{{formatted_ref_keyword}}}}}</a>")
                    else:
                        ref_frame = kanji_to_frame.get(content)
                        if ref_frame is not None and ref_frame in heisig_keyword_map:
                            ref_entry = heisig_keyword_map.get(ref_frame)
                            if ref_entry:
                                ref_keyword = ref_entry.heisig_keyword
                                if ref_keyword.lower() != "darken":
                                    formatted_ref_keyword = ref_keyword.replace(" ", "*")
                                    referenced_parts.add(f"<a href='#{ref_frame}'>@KJ{{{{{formatted_ref_keyword}}}}}</a>")
                    start = story.find('{', end + 1)

                referenced_parts_str = ", ".join(sorted(referenced_parts))

                # Column 6: Kanji Using This Kanji
                using_kanji = frame_number_map.get(frame_number, [])
                using_kanji_str = ", ".join(
                    f"<a href='#{ref_frame}'>@KJ{{{{{heisig_keyword_map[ref_frame].heisig_keyword.replace(' ', '*')}}}}}</a>"
                    for ref_frame in sorted(using_kanji)
                    if ref_frame in heisig_keyword_map and heisig_keyword_map[ref_frame].heisig_keyword.lower() != "darken"
                )

                html_content += f"""
                <tr id="{frame_number}">
                    <td>{frame_number}</td>
                    <td>{keyword}</td>
                    <td>{kanji}</td>
                    <td>{story}</td>
                    <td>{referenced_parts_str}</td>
                    <td>{using_kanji_str}</td>
                </tr>
                """

    html_content += """
        </table>
    </body>
    </html>
    """

    # Write HTML content to the specified output file
    with open(output_file, "w", encoding="utf-8") as html_file:
        html_file.write(html_content)
    print(f"HTML table generated and saved to {output_file}.")

def main():
    if len(sys.argv) < 3:
        print("Usage: python script.py <csv_file> <output_file>")
        sys.exit(1)

    file_name = sys.argv[1]
    output_file = sys.argv[2]

    entries, heisig_keyword_map, frame_number_map, missing_kanji_map, kanji_to_frame = parse_csv(file_name)

    # Output frame_number_map (if enabled)
    if DISPLAY_FRAME_NUMBER_MAP:
        print("\nFrame Number Map:")
        for frame in sorted(frame_number_map.keys()):
            print(f"{frame}: {frame_number_map[frame]}")

    # Output missing kanji (only if there are missing kanji)
    if missing_kanji_map:
        print("\nKANJI WITHOUT FRAME Reports:")
        for kanji, frames in missing_kanji_map.items():
            print(f"KANJI WITHOUT FRAME: '{kanji}' referenced in frames: {sorted(frames)}")

    # Generate HTML table
    generate_html_table(entries, heisig_keyword_map, frame_number_map, missing_kanji_map, kanji_to_frame, output_file)

if __name__ == "__main__":
    main()
