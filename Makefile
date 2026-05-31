UV ?= uv
PELICANOPTS=

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE), 1)
	PELICANOPTS += --relative-urls
endif

help:
	@echo 'Makefile for The Changelog Ecosystem site'
	@echo ''
	@echo 'Data collection:'
	@echo '   make gather            query package registries for tool metadata'
	@echo '   make discover          discover new changelog/release tools'
	@echo ''
	@echo 'Page generation:'
	@echo '   make generate-pages    generate Pelican pages from data/ JSON'
	@echo ''
	@echo 'Site build:'
	@echo '   make html              (re)generate the web site'
	@echo '   make build             generate-pages + html (full pipeline)'
	@echo '   make clean             remove the generated files'
	@echo '   make serve [PORT=8000] serve site at http://localhost:8000'
	@echo '   make devserver         serve and auto-regenerate on change'
	@echo '   make publish           generate using production settings'
	@echo ''
	@echo 'Set DEBUG=1 to enable Pelican debug output.'
	@echo ''

# ── Data collection ────────────────────────────────────────────────────────────

gather:
	uv run python gather_metadata.py

discover:
	uv run python discover_tools.py

# ── Page generation ────────────────────────────────────────────────────────────

generate-pages:
	uv run python generate_pages.py

# ── Full pipeline ──────────────────────────────────────────────────────────────

build: generate-pages html

# ── Pelican site build ─────────────────────────────────────────────────────────

html:
	uv run pelican "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

clean:
	[ ! -d "$(OUTPUTDIR)" ] || rm -rf "$(OUTPUTDIR)"

regenerate:
	uv run pelican -r "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

serve:
	uv run pelican -l "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

devserver:
	uv run pelican -lr "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

publish:
	uv run pelican "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(PUBLISHCONF)" $(PELICANOPTS)

.PHONY: help gather discover generate-pages build html clean regenerate serve devserver publish
