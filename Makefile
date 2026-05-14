EXTENSION_ID = lilypad@shendrew.github.io
EXTENSION_DIR = $(HOME)/.local/share/gnome-shell/extensions/$(EXTENSION_ID)

.DEFAULT_GOAL := help

all: build install lint

.PHONY: build install help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile GSettings schemas
	glib-compile-schemas --strict --targetdir=schemas/ schemas

install: ## Install extension to local GNOME Shell
	mkdir -p $(EXTENSION_DIR)
	cp -R ./* $(EXTENSION_DIR)

publish: ## Build extension zip for publishing
	rm -rf build
	mkdir build
	cp LICENSE ./build
	cp *.js ./build
	cp metadata.json ./build
	cp stylesheet.css ./build
	cp -r ui ./build
	cp -r preferences ./build
	cp -r effects ./build
	cp -r apps ./build
	cp README.md ./build
	cp CHANGELOG.md ./build
	cp -R schemas ./build
	rm -rf ./build/_*.js
	rm -rf ./build/utils.js
	rm -rf ./build/drawing.js
	rm -rf ./build/chamfer.js
	rm -rf ./build/imports_*
	rm -rf ./*.zip
	cd build ; \
	zip -qr ../$(EXTENSION_ID).zip .

install-zip: publish ## Install from built zip file
	echo "installing zip..."
	rm -rf $(EXTENSION_DIR)
	mkdir -p $(EXTENSION_DIR)
	unzip -q $(EXTENSION_ID).zip -d $(EXTENSION_DIR)

g4X: build ## Transpile for GNOME 4X compatibility
	rm -rf ./build
	mkdir -p ./build
	mkdir -p ./build/apps
	mkdir -p ./build/preferences
	python3 ./transpile.py
	rm -rf $(EXTENSION_DIR)
	mkdir -p $(EXTENSION_DIR)
	cp -R ./schemas ./build
	cp -R ./ui ./build
	cp ./apps/*.desktop ./build/apps
	# cp ./effects/*.glsl ./build/effects
	cp ./LICENSE* ./build
	cp ./CHANGELOG* ./build
	cp ./README* ./build
	cp ./stylesheet.css ./build
	cp -r ./build/* $(EXTENSION_DIR)

publish-g4X: g4X ## Build zip for publishing (GNOME 4X)
	echo "publishing..."
	cd build ; \
	zip -qr ../$(EXTENSION_ID).zip .

test-prefs-g4X: g4X ## Test preferences (GNOME 4X)
	gnome-extensions prefs $(EXTENSION_ID)

test-shell-g4X: g4X ## Run nested shell (GNOME 4X)
	env GNOME_SHELL_SLOWDOWN_FACTOR=2 \
		MUTTER_DEBUG_DUMMY_MODE_SPECS=1200x800 \
	 	MUTTER_DEBUG_DUMMY_MONITOR_SCALES=1 \
		dbus-run-session -- gnome-shell --devkit --wayland
	rm /run/user/1000/gnome-shell-disable-extensions

test-prefs: ## Open extension preferences
	gnome-extensions prefs $(EXTENSION_ID)

test-shell: install ## Run nested Wayland shell
	env GNOME_SHELL_SLOWDOWN_FACTOR=1 \
		MUTTER_DEBUG_DUMMY_MODE_SPECS=1280x800 \
	 	MUTTER_DEBUG_DUMMY_MONITOR_SCALES=1.5 \
		dbus-run-session -- gnome-shell --devkit --wayland
	rm /run/user/1000/gnome-shell-disable-extensions

lint: ## Run ESLint
	eslint ./

xml-lint: ## Format XML/UI files
	cd ui ; \
	find . -name "*.ui" -type f -exec xmllint --output '{}' --format '{}' \;

pretty: xml-lint ## Format all JS and XML files
	rm -rf ./build/*
	prettier --single-quote --write "**/*.js"
