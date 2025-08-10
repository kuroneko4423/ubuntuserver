#!/bin/bash

# Install VS Code extensions for code-server

echo "Installing VS Code extensions..."

# General extensions
code-server --install-extension shd101wyy.markdown-preview-enhanced
code-server --install-extension yzhang.markdown-all-in-one
code-server --install-extension takumii.markdowntable
code-server --install-extension DavidAnson.vscode-markdownlint
code-server --install-extension jebbs.plantuml
code-server --install-extension redhat.vscode-yaml
code-server --install-extension hediet.vscode-drawio
code-server --install-extension ms-vscode.vscode-json
code-server --install-extension streetsidesoftware.code-spell-checker
code-server --install-extension ms-vscode.sublime-commands
code-server --install-extension mechatroner.rainbow-csv
code-server --install-extension MS-CEINTL.vscode-language-pack-ja

# Frontend extensions
code-server --install-extension george-alisson.html-preview-vscode
code-server --install-extension ms-vscode.vscode-typescript-next
code-server --install-extension Vue.volar
code-server --install-extension ms-vscode.vscode-html-language-features

# Java extensions
code-server --install-extension vscjava.vscode-java-pack
code-server --install-extension vscjava.vscode-spring-boot-dashboard
code-server --install-extension vscjava.vscode-spring-initializr

# Python extensions
code-server --install-extension ms-python.python
code-server --install-extension ms-python.flake8
code-server --install-extension ms-python.black-formatter
code-server --install-extension ms-python.django
code-server --install-extension ms-toolsai.jupyter
code-server --install-extension ms-python.pylint

# AI Agent extension
code-server --install-extension RooVeterinaryInc.roo-cline

# Database extension
code-server --install-extension cweijan.vscode-database-client2

# Mobile development extensions
code-server --install-extension Dart-Code.dart-code
code-server --install-extension Dart-Code.flutter

echo "All extensions installed successfully!"