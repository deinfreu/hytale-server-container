DISCORD_WEBHOOK_URL ?= 

.PHONY: test-discord

# Test Discord notification locally using `act`
test-discord:
	@WEBHOOK_URL="$(DISCORD_WEBHOOK_URL)"; \
	if [ -z "$$WEBHOOK_URL" ] && [ -f .secrets ]; then \
		WEBHOOK_URL="$$(grep '^DISCORD_WEBHOOK_URL=' .secrets | cut -d'=' -f2- | tr -d '\"' | tr -d "'";)"; \
	fi; \
	if [ -z "$$WEBHOOK_URL" ]; then \
		echo "Error: DISCORD_WEBHOOK_URL is not set. Pass it via DISCORD_WEBHOOK_URL='https://...' or put it in a .secrets file."; \
		exit 1; \
	fi; \
	act workflow_dispatch \
		-W .github/workflows/test-discord.yml \
		--secret DISCORD_WEBHOOK_URL="$$WEBHOOK_URL" \
		--container-architecture linux/amd64