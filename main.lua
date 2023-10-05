GRAVITE = 9.81
VENT = 0
TAILLE_BLOC = 50
JOUEUR_TAILLEX = 50
JOUEUR_TAILLEY = 50
JOUEUR_VITESSE = 300
JOUEUR_VITESSE_SAUT = -300
JOUEUR_VITESSE_CHUTE_MAX = 600
JOUEUR_HITBOX = nil
JOUEUR_SURLESOL = false
JOUEUR = nil
NIVEAU = {
    blocs = {},
    tailleY = 0
}
IMAGES = {
    joueur =  love.graphics.newImage("images/joueur.png"),
    bloc = love.graphics.newImage("images/bloc.png")
}
MONDE = nil

function love.load()
    -- fenêtre
    local longueurFenetre, hauteurFenetre = love.window.getDesktopDimensions()
    love.window.setMode(longueurFenetre, hauteurFenetre)

    -- monde et gravité
    love.physics.setMeter(64) -- 1 mètre = 64 pixels
    MONDE = love.physics.newWorld(VENT * 64, GRAVITE * 64)

    -- niveau
    local niveau = chargerNiveaux("niveaux/niveau_1.txt")
    local joueurPositionDebutX = 0
    local joueurPositionDebutY = 0
    for y, ligne in ipairs(niveau) do
        NIVEAU.tailleY = math.max(NIVEAU.tailleY, y)
        for x, caractere in ipairs(ligne) do
            if caractere == "x" then
                table.insert(
                    NIVEAU.blocs,
                    creerObjetPhysique(
                        x * TAILLE_BLOC, y * TAILLE_BLOC,
                        TAILLE_BLOC, TAILLE_BLOC,
                        "static"
                    )
                )
            elseif caractere == "j" then
                joueurPositionDebutX = x * TAILLE_BLOC
                joueurPositionDebutY = y * TAILLE_BLOC
            end
        end
    end

    -- joueur
    JOUEUR = creerObjetPhysique(
        joueurPositionDebutX, joueurPositionDebutY,
        JOUEUR_TAILLEX, JOUEUR_TAILLEY,
        "dynamic"
    )
    JOUEUR.corps:setFixedRotation(true)
end

function love.update(dt)
    bougerJoueur(dt)
    MONDE:update(dt)
end

function bougerJoueur(dt)
    local vx = 0

    -- bouger à gauche et à droite
    if love.keyboard.isDown("right") then
        vx = vx + JOUEUR_VITESSE
    end
    if love.keyboard.isDown("left") then
        vx = vx - JOUEUR_VITESSE
    end

    -- saut
    local _, vy = JOUEUR.corps:getLinearVelocity()
    if love.keyboard.isDown("space") then
        -- TODO seulement quand le JOUEUR est sur le sol
        vy = JOUEUR_VITESSE_SAUT
    end

    -- vitesse de chute maximale
    vy = math.min(math.max(vy, -JOUEUR_VITESSE_CHUTE_MAX), JOUEUR_VITESSE_CHUTE_MAX)
    JOUEUR.corps:setLinearVelocity(vx, vy)

    -- quand le joueur tombe, on le fait remonter
    local maxY = (NIVEAU.tailleY + 1) * TAILLE_BLOC
    while JOUEUR.corps:getY() > maxY do
        JOUEUR.corps:setY(JOUEUR.corps:getY() - maxY)
    end

    -- print(JOUEUR.corps:getY())
end

function love.draw()
    dessinerJoueur()
    dessinerNiveau()
end

function dessinerJoueur()
    love.graphics.draw(
        IMAGES.joueur,
        JOUEUR.corps:getX() - JOUEUR_TAILLEX / 2,
        JOUEUR.corps:getY() - JOUEUR_TAILLEY / 2,
        0, -- orientation
        JOUEUR_TAILLEX / IMAGES.joueur:getWidth(), -- scaleX
        JOUEUR_TAILLEY / IMAGES.joueur:getHeight() -- scaleY
    )
    -- TODO for some strange reason, player sometimes gets stuck on the ground
    print(JOUEUR.corps:getY())
end

function dessinerNiveau()
    for b = 1, #NIVEAU.blocs do
        love.graphics.draw(
            IMAGES.bloc,
            NIVEAU.blocs[b].corps:getX() - TAILLE_BLOC / 2,
            NIVEAU.blocs[b].corps:getY() - TAILLE_BLOC / 2
        )
    end
end

function love.keypressed(touche)
    if touche == "escape" then
        love.event.quit()
    end
end

function coordonnees(hitbox)
    return hitbox.corps:getX(), hitbox.corps:getY()
end

function creerObjetPhysique(x, y, tailleX, tailleY, type)
    local objet = {
        corps = love.physics.newBody(MONDE, x, y, type),
        forme = love.physics.newRectangleShape(tailleX, tailleY)
    }
    objet.fixture = love.physics.newFixture(objet.corps, objet.forme)
    objet.fixture:setFriction(0)
    return objet
end

function chargerNiveaux(path)
    local niveau = {}
    local y = 1
    for line in love.filesystem.lines(path) do
        niveau[y] = {}
        local x = 1
        for s in line:gmatch(".") do
            niveau[y][x] = s
            x = x + 1
        end
        y = y + 1
    end

    return niveau
end
