archive: bin/archive.tar

.PHONY: bin/archive.tar

bin/archive.tar: 
	git archive HEAD --format  tar | gzip -9 > bin/archive.tar

bundle: bin/repo.bundle

.PHONY: bin/repo.bundle

bin/repo.bundle:
	git bundle create $@ master
