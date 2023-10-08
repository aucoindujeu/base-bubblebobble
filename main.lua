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
NIVEAU = {
    blocs = {},
    tailleY = 0
}

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

    -- saut
    if love.keyboard.isDown("space") then
        -- TODO seulement quand le JOUEUR est sur le sol
        -- TODO comment sauter plus haut en fonction de la durée pendant laquelle on appuie?
        JOUEUR.vy = -JOUEUR_VITESSE_SAUT
    else
        JOUEUR.vy = JOUEUR.vy + GRAVITE * dt
    end

    -- Vitesse de chute à ne pas dépasser
    if JOUEUR.vy > JOUEUR_VITESSE_CHUTE_MAX then
        JOUEUR.vy = JOUEUR_VITESSE_CHUTE_MAX
    end

    -- TODO collisions droite/gauche
    for y, ligne in ipairs(NIVEAU.blocs) do
        for x, bloc in ipairs(ligne) do
            if bloc == 1 then                                                                   -- il y a un obstacle
                if JOUEUR.vy ~= 0 and math.abs(JOUEUR.x - x) < JOUEUR_TAILLE_X / 2 + 1 / 2 then -- alignement vertical
                    -- TODO ça marche mais c'est illisible...
                    local distanceDebut = 0
                    local distanceFin = 0
                    local limitVy = 0
                    if JOUEUR.vy > 0 then -- test collision avec bloc en dessous
                        distanceDebut = y - 1 / 2 - JOUEUR_TAILLE_Y / 2 - JOUEUR.y
                        distanceFin = distanceDebut - JOUEUR.vy * dt
                        limitVy = distanceDebut/dt
                        -- if -JOUEUR.y - JOUEUR_TAILLE_Y / 2 + y - 1 / 2 >= 0 and -JOUEUR.y - JOUEUR_TAILLE_Y / 2 - JOUEUR.vy * dt + y - 1 / 2 < 0 then
                        -- JOUEUR.vy = (y - 1 / 2 - JOUEUR_TAILLE_Y / 2 - JOUEUR.y) / dt
                        -- end
                    else -- test collision avec bloc au dessus TODO comment simplifier ces deux opérations quasi identiques?
                        distanceDebut = JOUEUR.y - JOUEUR_TAILLE_Y / 2 - 1 / 2 - y
                        distanceFin = distanceDebut + JOUEUR.vy * dt
                        limitVy = -distanceDebut/dt
                        -- if JOUEUR.y - JOUEUR_TAILLE_Y / 2 - y - 1 / 2 >= 0 and JOUEUR.y - JOUEUR_TAILLE_Y / 2 + JOUEUR.vy * dt - y - 1 / 2 < 0 then
                            -- JOUEUR.vy = (y + 1 / 2 + JOUEUR_TAILLE_Y / 2 - JOUEUR.y) / dt
                        -- end
                    end
                    if distanceDebut >= 0 and distanceFin < 0 then
                        JOUEUR.vy = limitVy
                    end
                end
            end
        end
    end

    -- déplacement
    JOUEUR.x = JOUEUR.x + JOUEUR.vx * dt
    JOUEUR.y = JOUEUR.y + JOUEUR.vy * dt

    -- quand le joueur tombe, on le fait remonter
    while JOUEUR.y > #NIVEAU.blocs do
        JOUEUR.y = JOUEUR.y - #NIVEAU.blocs
    end
end

function testCollisionJoueurBloc(x, y)
    -- retourne "true" si le joueur est à distance de collision du bloc de coordonnées (x,y)
    return math.abs(x - JOUEUR.x) < JOUEUR_TAILLE_X / 2 + 1 / 2 and math.abs(y - JOUEUR.y) < JOUEUR_TAILLE_Y / 2 + 1 / 2
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
        }
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
        end
        y = y + 1
    end

    return niveau
end
