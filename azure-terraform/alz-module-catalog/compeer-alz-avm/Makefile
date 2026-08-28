STACKS := $(shell find stacks -mindepth 1 -maxdepth 1 -type d | sort)

fmt:
	terraform fmt -recursive

validate:
	@set -e; for s in $(STACKS); do echo "== $$s =="; terraform -chdir=$$s init -backend=false -input=false; terraform -chdir=$$s validate; done
