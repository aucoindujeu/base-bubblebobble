GRAVITE = 9.81
VENT = 0
IMAGES = {
    joueur = love.graphics.newImage("images/joueur.png"),
    bloc = love.graphics.newImage("images/bloc.png")
}

-- hauteur/largeur relativement à un bloc
JOUEUR_TAILLE_X = 1.5
JOUEUR_TAILLE_Y = 1.5

JOUEUR_VITESSE = 5
JOUEUR_VITESSE_SAUT = 5
JOUEUR_VITESSE_CHUTE_MAX = 10

JOUEUR = {
    x = 0,
    y = 0,
    vx = 0,
    vy = 0
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
    JOUEUR.x = NIVEAU.positionDepartJoueur.x
    JOUEUR.y = NIVEAU.positionDepartJoueur.y
end

function love.update(dt)
    bougerJoueur(dt)
end

function bougerJoueur(dt)
    -- TODO contrôle à la manette
    -- bouger à gauche et à droite
    JOUEUR.vx = 0
    if love.keyboard.isDown("right") then
        JOUEUR.vx = JOUEUR.vx + JOUEUR_VITESSE
    end
    if love.keyboard.isDown("left") then
        JOUEUR.vx = JOUEUR.vx - JOUEUR_VITESSE
    end

    -- Gravité
    JOUEUR.vy = JOUEUR.vy + GRAVITE * dt

    -- saut
    local joueurSurLeSol = testJoueurSurLeSol()
    if love.keyboard.isDown("space") and joueurSurLeSol then
        -- TODO comment sauter plus haut en fonction de la durée pendant laquelle on appuie?
        JOUEUR.vy = -JOUEUR_VITESSE_SAUT
    end

    -- Vitesse de chute à ne pas dépasser
    if JOUEUR.vy > JOUEUR_VITESSE_CHUTE_MAX then
        JOUEUR.vy = JOUEUR_VITESSE_CHUTE_MAX
    end

    -- collisions
    for y, ligne in ipairs(NIVEAU.blocs) do
        for x, bloc in ipairs(ligne) do
            if bloc == 1 then
                -- est-ce qu'il y a collision?
                if JOUEUR.vy > 0 and testCollision( -- dessous
                        JOUEUR.x, JOUEUR.y + JOUEUR_TAILLE_Y / 2 + JOUEUR.vy * dt / 2,
                        JOUEUR_TAILLE_X, JOUEUR.vy * dt,
                        x, y, 1, 1
                    ) then
                    JOUEUR.vy = (y - 1 / 2 - JOUEUR_TAILLE_Y / 2 - JOUEUR.y) / dt
                end
                if JOUEUR.vy < 0 and testCollision( -- dessus
                        JOUEUR.x, JOUEUR.y - JOUEUR_TAILLE_Y / 2 + JOUEUR.vy * dt / 2,
                        JOUEUR_TAILLE_X, -JOUEUR.vy * dt,
                        x, y, 1, 1
                    ) then
                    JOUEUR.vy = (y + 1 / 2 + JOUEUR_TAILLE_Y / 2 - JOUEUR.y) / dt
                end
                if JOUEUR.vx > 0 and testCollision( -- droite
                        JOUEUR.x + JOUEUR_TAILLE_X / 2 + JOUEUR.vx * dt / 2, JOUEUR.y,
                        JOUEUR.vx * dt, JOUEUR_TAILLE_Y,
                        x, y, 1, 1
                    ) then
                    JOUEUR.vx = (x - 1 / 2 - JOUEUR_TAILLE_X / 2 - JOUEUR.x) / dt
                end
                if JOUEUR.vx < 0 and testCollision( -- gauche
                        JOUEUR.x - JOUEUR_TAILLE_X / 2 + JOUEUR.vx * dt / 2, JOUEUR.y,
                        -JOUEUR.vx * dt, JOUEUR_TAILLE_Y,
                        x, y, 1, 1
                    ) then
                    JOUEUR.vx = (x + 1 / 2 + JOUEUR_TAILLE_X / 2 - JOUEUR.x) / dt
                end
            end
        end
    end

    -- déplacement
    JOUEUR.x = JOUEUR.x + JOUEUR.vx * dt
    JOUEUR.y = JOUEUR.y + JOUEUR.vy * dt

    -- on garde le joueur dans les bornes du terrain
    JOUEUR.x = math.min(NIVEAU.tailleX, math.max(1, JOUEUR.x))

    -- quand le joueur tombe, on le fait remonter
    while JOUEUR.y > #NIVEAU.blocs do
        JOUEUR.y = JOUEUR.y - #NIVEAU.blocs
    end
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

function testJoueurSurLeSol()
    -- est-ce que le joueur est sur le sol?
    local solY = math.floor(JOUEUR.y + JOUEUR_TAILLE_Y / 2 + 1 / 2)
    if solY < 1 or solY > #NIVEAU.blocs then
        return false
    end
    local minX = math.max(1, math.ceil(JOUEUR.x - JOUEUR_TAILLE_X / 2 - 1 / 2))
    local maxX = math.min(#NIVEAU.blocs[solY], math.floor(JOUEUR.x + JOUEUR_TAILLE_X / 2 + 1 / 2))
    for solX = minX, maxX do
        if math.abs(solX - JOUEUR.x) < JOUEUR_TAILLE_X / 2 + 1 / 2 then
            if NIVEAU.blocs[solY][solX] == 1 then
                return true
            end
        end
    end
    return false
end

function love.draw()
    dessinerJoueur()
    dessinerNiveau()
end

function dessinerJoueur()
    love.graphics.draw(
        IMAGES.joueur,
        (JOUEUR.x - JOUEUR_TAILLE_X / 2) * ECHELLE_DESSIN,
        (JOUEUR.y - JOUEUR_TAILLE_Y / 2) * ECHELLE_DESSIN,
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
                    (y - 1 / 2) * ECHELLE_DESSIN
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
