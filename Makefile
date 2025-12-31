# Makefile for Research Pipeline

include scripts/rs.mk

.PHONY: clean help deploy-sidecar

help:
	@echo "Main Makefile Help:"
	@echo "  make help-rs        - Show Research Sidecar Workflow help"
	@echo "  make clean          - Clean up generated files"
	@echo "  make deploy-sidecar - Deploy to research-sidecar repository"
	@$(MAKE) help-rs

deploy-sidecar:
	git push research-sidecar rs-release:main

clean:
	rm -f *.pyc
	rm -rf __pycache__

clean:
	rm -f *.pyc
	rm -rf __pycache__
