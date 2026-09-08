.PHONY: test-discord

# Test Discord notification locally using `act`
test-discord:
	act workflow_dispatch \
		-W .github/workflows/test-discord.yml \
		--secret-file .secrets \
		--container-architecture linux/amd64