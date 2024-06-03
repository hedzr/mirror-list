SHELL := /bin/bash
GH_PAGE := docs
#  hedzr.github.io

.PHONY: deploy
deploy:
	cd $(GH_PAGE) && mkdocs gh-deploy --config-file ../mkdocs.yml --remote-branch master

# .PHONY: update-build-version
# update-build-version:
# 	git submodule update --remote --merge
# 	git add $(GH_PAGE)
# 	git commit -m "ci: update build version"

# .PHONY: publish
# publish: deploy update-build-version
# 	git push --no-verify

dev: preview
preview: live-preview
live-preview:
	mkdocs serve --dev-addr 0.0.0.0:7317 --open --dirty

init-env:
	python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip
	pip install mkdocs
