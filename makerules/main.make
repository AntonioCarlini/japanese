archive: bin/japanese.tar

.PHONY: bin/japanese.tar

bin/japanese.tar: 
	git archive HEAD --format  tar | gzip -9 > bin/japanese.tar

bundle: bin/japanese.bundle

.PHONY: bin/japanese.bundle

bin/japanese.bundle:
	git bundle create $@ master
