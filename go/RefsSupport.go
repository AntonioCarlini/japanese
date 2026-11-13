package main

// Ported from scripts/RefsSupport.rb

import (
	"fmt"
	"regexp"
	"strings"

	"japanese/rubycompat"
)

// ref_data is the Ruby global $ref_data. references.data is read the first
// time a reference is needed, and never if there is none.
var ref_data *DataRefs

var jpod_re = regexp.MustCompile(`JPOD101-(\w+)-S(\d)-(\d\d\d)`)

// convert_ref returns nil (and no error) if the reference is not known.
func convert_ref(ref string, data_dir string) (*Reference, error) {
	if ref_data == nil {
		data_filename := data_dir
		if data_filename != "" && !strings.HasSuffix(data_filename, "/") {
			data_filename += "/"
		}
		data_filename += "references.data"
		loaded, err := DataRefs_create_from_file(data_filename)
		if err != nil {
			return nil, err
		}
		ref_data = loaded
	}

	var r *Reference

	if m := jpod_re.FindStringSubmatch(ref); m != nil {
		level := m[1]
		season := m[2]
		number := rubycompat.ToI(m[3], 10)
		full_level_name := ""
		switch level {
		case "BG":
			full_level_name = "Beginner"
		case "UB":
			full_level_name = "Upper Beginner"
		case "LI":
			full_level_name = "Lower Intermediate"
		case "IN":
			full_level_name = "Intermediate"
		case "UI":
			full_level_name = "Upper Intermediate"
		}
		r = &Reference{
			ident:     ref,
			text:      fmt.Sprintf("JapanesePOD101.com, %s Season %s, Lesson #%d", full_level_name, season, number),
			alternate: "",
		}
	} else {
		r = ref_data.refs[ref]
		if r == nil {
			debug_out(fmt.Sprintf("@REF{{%s}} => nil", ref))
		} else {
			debug_out(fmt.Sprintf("@REF{{%s}} => [%s / %s]", ref, r.text, r.alternate))
		}
	}
	return r, nil
}
