play:
	love ./src/

love:
	mkdir -p dist
	cd src && zip -r ../dist/projetvide.love .

js: love
	love.js -c --title="Projet vide" ./dist/projetvide.love ./dist/js
