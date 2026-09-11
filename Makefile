APP_NAME = Portlessman
BUNDLE = build/$(APP_NAME).app
INSTALL_DIR = /Applications

.PHONY: all build run install clean

all: build

build:
	@./scripts/bundle.sh

run: build
	@echo "🚀 Launching $(APP_NAME)..."
	@open $(BUNDLE)

install: build
	@echo "📂 Installing to $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(BUNDLE)" "$(INSTALL_DIR)/"
	@echo "✅ Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	@rm -rf .build build
	@echo "🧹 Cleaned build artifacts"
