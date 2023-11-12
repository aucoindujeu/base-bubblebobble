play:
	love ./src/

love:
	mkdir -p dist
	cd src && zip -r ../dist/base-bubblebobble.love .

js: love
	love.js -c --title="Projet vide" ./dist/base-bubblebobble.love ./dist/js
