import csv
import sys
from collections import defaultdict

# Constants
KANJI_MAX_FRAME_NUMBER = 3000
REPORT_NON_HEISIG_KANJI = False  # Set to True to report non-Heisig kanji
DISPLAY_FRAME_NUMBER_MAP = False  # Set to True to display the frame number map

class Entry:
    def __init__(self, frame_number, kanji, heisig_keyword, story):
        self.frame_number = frame_number
        self.kanji = kanji
        self.heisig_keyword = heisig_keyword
        self.story = story

def parse_csv(file_name):
    entries = []
    heisig_keyword_map = {}
    frame_number_map = defaultdict(list)
    missing_kanji_map = defaultdict(set)
    keyword_count = defaultdict(int)
    frame_to_kanji = {}  # Maps frame numbers to kanji

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
            heisig_keyword_map[heisig_keyword] = Entry(frame_number, kanji, heisig_keyword, story)

            # Create Entry object
            entry = Entry(frame_number, kanji, heisig_keyword, story)
            entries.append(entry)

            # Map frame number to kanji
            frame_to_kanji[frame_number] = kanji

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
                    # Handle frame number references (e.g., {16})
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
                    ref_frame = next((e.frame_number for e in entries if e.kanji == ref_kanji), None)

                if ref_frame is not None:
                    if ref_frame <= KANJI_MAX_FRAME_NUMBER:
                        frame_number_map[ref_frame].append(frame_number)
                else:
                    if REPORT_NON_HEISIG_KANJI or (ref_kanji in frame_to_kanji.values() and frame_to_kanji[ref_frame] <= KANJI_MAX_FRAME_NUMBER):
                        missing_kanji_map[ref_kanji].add(frame_number)

    return entries, heisig_keyword_map, frame_number_map, missing_kanji_map

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <csv_file>")
        sys.exit(1)

    file_name = sys.argv[1]
    entries, heisig_keyword_map, frame_number_map, missing_kanji_map = parse_csv(file_name)

    # Output frame_number_map (if enabled)
    if DISPLAY_FRAME_NUMBER_MAP:
        print("\nFrame Number Map:")
        for frame in sorted(frame_number_map.keys()):
            print(f"{frame}: {frame_number_map[frame]}")

    # Output missing kanji
    print("\nKANJI WITHOUT FRAME Reports:")
    for kanji, frames in missing_kanji_map.items():
        print(f"KANJI WITHOUT FRAME: '{kanji}' referenced in frames: {sorted(frames)}")

if __name__ == "__main__":
    main()