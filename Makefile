UV ?= uv
export UV_CACHE_DIR ?= $(CURDIR)/.uv-cache
PELICANOPTS=
GHA_WORKFLOWS=.github/workflows

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
	@echo 'Quality gates:'
	@echo '   make quality-python    lint generated artifacts and internal links'
	@echo '   make quality-links     cached external link audit'
	@echo '   make quality-node      validate HTML, CSS browser support, and a11y'
	@echo '   make quality           build + all quality gates'
	@echo ''
	@echo 'Documentation:'
	@echo '   make docs              build Read the Docs maintainer docs'
	@echo '   make docs-serve        preview maintainer docs locally'
	@echo ''
	@echo 'GitHub Actions:'
	@echo '   make gha-validate      YAML parse + zizmor workflow audit'
	@echo '   make gha-pin           pin GitHub Actions refs to commit SHAs'
	@echo '   make gha-upgrade       gha-pin + gha-validate'
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

# ── Quality gates ──────────────────────────────────────────────────────────────

quality-python: html
	uv run python scripts/check_pelican_artifacts.py --site-dir "$(OUTPUTDIR)"
	uv run python scripts/check_links.py --site-dir "$(OUTPUTDIR)" --internal-only

quality-links: html
	uv run python scripts/check_links.py --site-dir "$(OUTPUTDIR)"

quality-python-internal: html
	uv run python scripts/check_pelican_artifacts.py --site-dir "$(OUTPUTDIR)"
	uv run python scripts/check_links.py --site-dir "$(OUTPUTDIR)" --internal-only

quality-node: html
	npm run quality

quality: build quality-python quality-node

# ── Maintainer docs ───────────────────────────────────────────────────────────

docs:
	set UV_CACHE_DIR=& uv run mkdocs build

docs-serve:
	set UV_CACHE_DIR=& uv run mkdocs serve

# ── GitHub Actions maintenance ────────────────────────────────────────────────

gha-validate:
	@echo "Validating GitHub Actions workflows"
	uv run python -c "import pathlib, yaml; [yaml.safe_load(p.read_text(encoding='utf-8')) for p in pathlib.Path('$(GHA_WORKFLOWS)').glob('*.yml')]; print('YAML parse OK')"
	uvx zizmor --no-progress --no-exit-codes .

gha-pin:
	@echo "Pinning GitHub Actions to current commit SHAs"
	uv run python -c "import os, subprocess; token=os.environ.get('GITHUB_TOKEN') or subprocess.run(['gh', 'auth', 'token'], capture_output=True, text=True).stdout.strip(); assert token, 'Set GITHUB_TOKEN or run: gh auth login'; env=dict(os.environ, GITHUB_TOKEN=token); raise SystemExit(subprocess.run(['gha-update'], env=env).returncode)"

gha-upgrade: gha-pin gha-validate
	@echo "GitHub Actions upgrade complete"

.PHONY: help gather discover generate-pages build html clean regenerate serve devserver publish quality-python quality-links quality-python-internal quality-node quality docs docs-serve gha-validate gha-pin gha-upgrade
