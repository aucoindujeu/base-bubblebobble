GRAVITE = 9.81 * 7
VENT = 0
IMAGES = {
    joueur = love.graphics.newImage("images/joueur.png"),
    bloc = love.graphics.newImage("images/bloc.png")
}

-- hauteur/largeur relativement à un bloc
JOUEUR_TAILLE_X = 1.5
JOUEUR_TAILLE_Y = 1.5

JOUEUR_VITESSE = 8
JOUEUR_VITESSE_SAUT = 20
JOUEUR_VITESSE_CHUTE_MAX = 10

JOUEURS = {
    {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        joystick = nil
    }
}
NIVEAU = {}

-- On considère que les blocs sont de taille 1x1. Quand on les dessine, ils ont cette
-- taille.
ECHELLE_DESSIN = 50

function love.load()
    -- fenêtre
    local longueurFenetre, hauteurFenetre = love.window.getDesktopDimensions()
    love.window.setMode(
        longueurFenetre, hauteurFenetre,
        { resizable = true }
    )

    -- niveau
    NIVEAU = chargerNiveau("niveaux/niveau_1.txt")
    -- TODO position des autres joueurs?
    JOUEURS[1].x = NIVEAU.positionDepartJoueur.x
    JOUEURS[1].y = NIVEAU.positionDepartJoueur.y
end

function love.joystickadded(joystick)
    -- TODO ajouter un menu pour assigner facilement un joystick à chaque joueur
    JOUEURS[1].joystick = joystick
end

function love.update(dt)
    for j = 1, #JOUEURS do
        bougerJoueur(JOUEURS[j], dt)
    end
end

function bougerJoueur(joueur, dt)
    -- TODO contrôle à la manette
    -- bouger à gauche et à droite
    joueur.vx = lireVitesseJoueur(joueur)

    -- Gravité
    joueur.vy = joueur.vy + GRAVITE * dt

    -- saut
    local joueurSurLeSol = testJoueurSurLeSol(joueur)
    if lireSautJoueur(joueur) and joueurSurLeSol then
        -- TODO comment sauter plus haut en fonction de la durée pendant laquelle on appuie?
        joueur.vy = -JOUEUR_VITESSE_SAUT
    end

    -- Vitesse de chute à ne pas dépasser
    if joueur.vy > JOUEUR_VITESSE_CHUTE_MAX then
        joueur.vy = JOUEUR_VITESSE_CHUTE_MAX
    end

    -- collisions
    -- TODO collisions entre joueurs?
    for y, ligne in ipairs(NIVEAU.blocs) do
        for x, bloc in ipairs(ligne) do
            if bloc == 1 then
                -- est-ce qu'il y a collision?
                if joueur.vy > 0 and testCollision( -- dessous
                        joueur.x, joueur.y + JOUEUR_TAILLE_Y / 2 + joueur.vy * dt / 2,
                        JOUEUR_TAILLE_X, joueur.vy * dt,
                        x, y, 1, 1
                    ) then
                    joueur.vy = (y - 1 / 2 - JOUEUR_TAILLE_Y / 2 - joueur.y) / dt
                end
                if joueur.vy < 0 and testCollision( -- dessus
                        joueur.x, joueur.y - JOUEUR_TAILLE_Y / 2 + joueur.vy * dt / 2,
                        JOUEUR_TAILLE_X, -joueur.vy * dt,
                        x, y, 1, 1
                    ) then
                    joueur.vy = (y + 1 / 2 + JOUEUR_TAILLE_Y / 2 - joueur.y) / dt
                end
                if joueur.vx > 0 and testCollision( -- droite
                        joueur.x + JOUEUR_TAILLE_X / 2 + joueur.vx * dt / 2, joueur.y,
                        joueur.vx * dt, JOUEUR_TAILLE_Y,
                        x, y, 1, 1
                    ) then
                    joueur.vx = (x - 1 / 2 - JOUEUR_TAILLE_X / 2 - joueur.x) / dt
                end
                if joueur.vx < 0 and testCollision( -- gauche
                        joueur.x - JOUEUR_TAILLE_X / 2 + joueur.vx * dt / 2, joueur.y,
                        -joueur.vx * dt, JOUEUR_TAILLE_Y,
                        x, y, 1, 1
                    ) then
                    joueur.vx = (x + 1 / 2 + JOUEUR_TAILLE_X / 2 - joueur.x) / dt
                end
            end
        end
    end

    -- déplacement
    joueur.x = joueur.x + joueur.vx * dt
    joueur.y = joueur.y + joueur.vy * dt

    -- on garde le joueur dans les bornes du terrain
    joueur.x = math.min(NIVEAU.tailleX, math.max(1, joueur.x))

    -- quand le joueur tombe, on le fait remonter
    while joueur.y > #NIVEAU.blocs do
        joueur.y = joueur.y - #NIVEAU.blocs
    end
end

function lireVitesseJoueur(joueur)
    -- index est le numéro du joueur
    local directionX = 0
    if love.keyboard.isDown("right") then
        directionX = directionX + 1
    end
    if love.keyboard.isDown("left") then
        directionX = directionX - 1
    end
    if joueur.joystick then
        local joystickX = joueur.joystick:getGamepadAxis("leftx")
        if math.abs(joystickX) < 0.2 then
            joystickX = 0
        end
        directionX = directionX + joystickX
    end
    directionX = math.max(-1, math.min(directionX, 1))
    return directionX * JOUEUR_VITESSE
end

function lireSautJoueur(joueur)
    if love.keyboard.isDown("space") then
        return true
    end
    if joueur.joystick then
        if joueur.joystick:isGamepadDown("a") or joueur.joystick:isGamepadDown("b") then
            return true
        end
    end
    return false
end

function testCollision(x1, y1, sx1, sy1, x2, y2, sx2, sy2)
    -- retourne "true" si les deux rectangles se superposent
    if x1 + sx1 / 2 <= x2 - sx2 / 2 or x2 + sx2 / 2 <= x1 - sx1 / 2 then
        return false
    end
    if y1 + sy1 / 2 <= y2 - sy2 / 2 or y2 + sy2 / 2 <= y1 - sy1 / 2 then
        return false
    end
    return true
end

function testJoueurSurLeSol(joueur)
    -- est-ce que le joueur est sur le sol?
    local solY = math.floor(joueur.y + JOUEUR_TAILLE_Y / 2 + 1 / 2)
    if solY < 1 or solY > #NIVEAU.blocs then
        return false
    end
    local minX = math.max(1, math.ceil(joueur.x - JOUEUR_TAILLE_X / 2 - 1 / 2))
    local maxX = math.min(#NIVEAU.blocs[solY], math.floor(joueur.x + JOUEUR_TAILLE_X / 2 + 1 / 2))
    for solX = minX, maxX do
        if math.abs(solX - joueur.x) < JOUEUR_TAILLE_X / 2 + 1 / 2 then
            if NIVEAU.blocs[solY][solX] == 1 then
                return true
            end
        end
    end
    return false
end

function love.draw()
    for j = 1, #JOUEURS do
        dessinerJoueur(JOUEURS[j])
    end
    dessinerNiveau()
end

function dessinerJoueur(joueur)
    love.graphics.draw(
        IMAGES.joueur,
        (joueur.x - JOUEUR_TAILLE_X / 2) * ECHELLE_DESSIN,
        (joueur.y - JOUEUR_TAILLE_Y / 2) * ECHELLE_DESSIN,
        0,                                                             -- orientation
        (JOUEUR_TAILLE_X / IMAGES.joueur:getWidth()) * ECHELLE_DESSIN, -- scaleX
        (JOUEUR_TAILLE_Y / IMAGES.joueur:getHeight()) * ECHELLE_DESSIN -- scaleY
    )
end

function dessinerNiveau()
    for y = 1, #NIVEAU.blocs do
        for x = 1, #NIVEAU.blocs[y] do
            if NIVEAU.blocs[y][x] == 1 then
                love.graphics.draw(
                    IMAGES.bloc,
                    (x - 1 / 2) * ECHELLE_DESSIN,
                    (y - 1 / 2) * ECHELLE_DESSIN,
                    0,
                    (1 / IMAGES.bloc:getWidth()) * ECHELLE_DESSIN,
                    (1 / IMAGES.bloc:getHeight()) * ECHELLE_DESSIN

                )
            end
        end
    end
end

function love.keypressed(touche)
    if touche == "escape" then
        love.event.quit()
    end
end

function chargerNiveau(path)
    local niveau = {
        blocs = {},
        positionDepartJoueur = {
            x = 0,
            y = 0
        },
        tailleX = 0
    }
    local y = 1
    for line in love.filesystem.lines(path) do
        niveau.blocs[y] = {}
        for x = 1, #line do
            local caractere = line:sub(x, x)
            if caractere == "x" then
                niveau.blocs[y][x] = 1
            elseif caractere == "j" then
                niveau.positionDepartJoueur.x = x
                niveau.positionDepartJoueur.y = y
            else
                niveau.blocs[y][x] = 0
            end
            niveau.tailleX = math.max(niveau.tailleX, x)
        end
        y = y + 1
    end

    return niveau
end
