.DEFAULT_GOAL := help

PACKAGE ?= handshake
CASK_FILE := Casks/handshake.rb
FORMULA_FILE := Formula/nouli.rb
TAP ?= standing-desks/tap
export TAP
CASK := $(TAP)/handshake
export HOMEBREW_NO_AUTO_UPDATE := 1
export HOMEBREW_NO_ANALYTICS := 1
export HOMEBREW_NO_INSTALL_CLEANUP := 1
export PYTHONDONTWRITEBYTECODE := 1

.PHONY: help fmt link-tap lint test check audit-online install-smoke update protect-main

help:
	@echo 'make fmt            Format the cask'
	@echo 'make link-tap       Register this checkout as the local $(TAP)'
	@echo 'make check          Check cask style, audit, workflows, scripts, and updater tests'
	@echo 'make audit-online   Download and audit the released app'
	@echo 'make install-smoke  Install into a temporary app directory, verify, then uninstall'
	@echo 'make update         Update Handshake; PACKAGE=nouli selects the Nouli formula (requires gh auth)'
	@echo '                    Set RELEASE_TAG=vX.Y.Z to select a published stable release'
	@echo 'make protect-main   Configure maintainer/bot PR rules (requires APP_SLUG and admin auth)'

fmt:
	brew style --fix $(CASK_FILE) $(wildcard $(FORMULA_FILE))

link-tap:
	bash scripts/link-tap.sh

lint: link-tap
	brew style $(CASK_FILE) $(wildcard $(FORMULA_FILE))
	brew audit --cask $(CASK)
	actionlint
	shellcheck scripts/*.sh

test:
	python3 -m unittest discover -s tests -v

check: lint test

# Validate the pinned release independently of the latest GitHub release.
audit-online: link-tap
	brew audit --cask --online --except=livecheck_version $(CASK)

install-smoke: link-tap
	bash scripts/install-smoke.sh

update:
ifeq ($(PACKAGE),handshake)
	python3 scripts/update_cask.py
else ifeq ($(PACKAGE),nouli)
	python3 -m scripts.update_formula
else
	$(error PACKAGE must be handshake or nouli)
endif

protect-main:
	APP_SLUG="$(APP_SLUG)" python3 scripts/protect_main.py
