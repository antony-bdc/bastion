.PHONY: deps lint check apply test-vm

deps:
	ansible-galaxy collection install -r requirements.yml

lint:
	yamllint .
	ansible-lint

check: ## dry run with diff
	ansible-playbook site.yml --check --diff

apply:
	ansible-playbook site.yml

test-vm: ## run against the Vagrant VM
	ansible-playbook site.yml -i "192.168.56.10," -u vagrant \
	  --private-key .vagrant/machines/default/virtualbox/private_key \
	  -e '{"baseline_admin_users":[{"name":"ops","ssh_keys":["$(shell cat ~/.ssh/id_ed25519.pub)"]}]}'
