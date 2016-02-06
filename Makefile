bootstrap: install link shell app osx

.PHONY: install
install:
	@./bootstrap.d/install

.PHONY: link
link:
	@./bootstrap.d/link

.PHONY: shell
shell:
	@./bootstrap.d/shell

.PHONY: app
app:
	@./bootstrap.d/app

.PHONY: osx
osx:
	@./bootstrap.d/osx
