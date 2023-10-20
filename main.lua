GRAVITE = 9.81 * 7
VENT = 0
IMAGES = {
    joueur = love.graphics.newImage("images/joueur.png"),
    bloc = love.graphics.newImage("images/bloc.png"),
    monstre = love.graphics.newImage("images/monstre.png")
}

JOUEUR_VITESSE = 8
JOUEUR_VITESSE_SAUT = 20

MONSTRES_VITESSE = JOUEUR_VITESSE * 0.5

VITESSE_CHUTE_MAX = 10

NIVEAU = {}
JOUEURS = {}
MONSTRES = {}

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
    chargerNiveau("niveaux/niveau_1.txt")
end

function love.joystickadded(joystick)
    -- TODO ajouter un menu pour assigner facilement un joystick à chaque joueur
    JOUEURS[1].joystick = joystick
end

function love.update(dt)
    -- Déplacement des joueurs
    for j = 1, #JOUEURS do
        if JOUEURS[j].vivant then
            calculerVitesseJoueur(JOUEURS[j], dt)
            deplacerObjet(JOUEURS[j], dt)
        end
    end

    -- Déplacement des monstres
    for m = 1, #MONSTRES do
        if MONSTRES[m].vivant then
            calculerVitesseMonstre(MONSTRES[m], dt)
            deplacerObjet(MONSTRES[m], dt)
        end
    end
end

function calculerVitesseMonstre(monstre, dt)
    if monstre.vx == 0 and testObjetSurLeSol(monstre) then
        -- quand le monstre est sur le sol avec une vitesse nulle, on le fait se
        -- déplacer dans une direction au hasard
        monstre.vx = (math.random(0, 1) * 2 - 1) * MONSTRES_VITESSE
    end
    local vx = monstre.vx

    calculerVitesse(monstre, dt)

    if vx ~= 0 and monstre.vx == 0 then
        -- le monstre a fait une collision, on change de direction
        monstre.vx = -signe(vx) * MONSTRES_VITESSE
    end
end

function calculerVitesseJoueur(joueur, dt)
    -- bouger à gauche et à droite
    joueur.vx = lireVitesseJoueur(joueur)

    -- saut
    if lireSautJoueur(joueur) and testObjetSurLeSol(joueur) then
        -- TODO comment sauter plus haut en fonction de la durée pendant laquelle on appuie?
        joueur.vy = -JOUEUR_VITESSE_SAUT
    end

    calculerVitesse(joueur, dt)
end

function lireVitesseJoueur(joueur)
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

function calculerVitesse(objet, dt)
    -- On applique la gravité
    objet.vy = objet.vy + GRAVITE * dt

    -- Vitesse de chute à ne pas dépasser
    if objet.vy > VITESSE_CHUTE_MAX then
        objet.vy = VITESSE_CHUTE_MAX
    end

    -- collisions
    for y, ligne in ipairs(NIVEAU.blocs) do
        for x, bloc in ipairs(ligne) do
            if bloc == 1 then
                -- est-ce qu'il y a collision?
                if objet.vy > 0 and testCollision( -- dessous
                        objet.x, objet.y + objet.tailleY / 2 + objet.vy * dt / 2,
                        objet.tailleX, objet.vy * dt,
                        x, y, 1, 1
                    ) then
                    objet.vy = (y - 1 / 2 - objet.tailleY / 2 - objet.y) / dt
                end
                if objet.vy < 0 and testCollision( -- dessus
                        objet.x, objet.y - objet.tailleY / 2 + objet.vy * dt / 2,
                        objet.tailleX, -objet.vy * dt,
                        x, y, 1, 1
                    ) then
                    objet.vy = (y + 1 / 2 + objet.tailleY / 2 - objet.y) / dt
                end
                if objet.vx > 0 and testCollision( -- droite
                        objet.x + objet.tailleX / 2 + objet.vx * dt / 2, objet.y,
                        objet.vx * dt, objet.tailleY,
                        x, y, 1, 1
                    ) then
                    objet.vx = (x - 1 / 2 - objet.tailleX / 2 - objet.x) / dt
                end
                if objet.vx < 0 and testCollision( -- gauche
                        objet.x - objet.tailleX / 2 + objet.vx * dt / 2, objet.y,
                        -objet.vx * dt, objet.tailleY,
                        x, y, 1, 1
                    ) then
                    objet.vx = (x + 1 / 2 + objet.tailleX / 2 - objet.x) / dt
                end
            end
        end
    end
end

function deplacerObjet(objet, dt)
    -- déplacement
    objet.x = objet.x + objet.vx * dt
    objet.y = objet.y + objet.vy * dt

    -- on garde l'objet dans les bornes du terrain
    objet.x = math.min(NIVEAU.tailleX, math.max(1, objet.x))

    -- quand l'objet tombe, on le fait remonter
    while objet.y > #NIVEAU.blocs do
        objet.y = objet.y - #NIVEAU.blocs
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

function testObjetSurLeSol(objet)
    -- est-ce que l'objet est sur le sol?
    local solY = math.floor(objet.y + objet.tailleY / 2 + 1 / 2)
    if solY < 1 or solY > #NIVEAU.blocs then
        return false
    end
    local minX = math.max(1, math.ceil(objet.x - objet.tailleX / 2 - 1 / 2))
    local maxX = math.min(#NIVEAU.blocs[solY], math.floor(objet.x + objet.tailleX / 2 + 1 / 2))
    for solX = minX, maxX do
        if math.abs(solX - objet.x) < objet.tailleX / 2 + 1 / 2 then
            if NIVEAU.blocs[solY][solX] == 1 then
                return true
            end
        end
    end
    return false
end

function love.draw()
    dessinerNiveau()
    for m = 1, #MONSTRES do
        dessinerObjet(MONSTRES[m])
    end
    for j = 1, #JOUEURS do
        dessinerObjet(JOUEURS[j])
    end
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

function dessinerObjet(objet)
    love.graphics.draw(
        objet.image,
        (objet.x - objet.tailleX / 2) * ECHELLE_DESSIN,
        (objet.y - objet.tailleY / 2) * ECHELLE_DESSIN,
        0,                                                         -- orientation
        (objet.tailleX / objet.image:getWidth()) * ECHELLE_DESSIN, -- scaleX
        (objet.tailleY / objet.image:getHeight()) * ECHELLE_DESSIN -- scaleY
    )
end

function love.keypressed(touche)
    if touche == "escape" then
        love.event.quit()
    end
end

function chargerNiveau(path)
    NIVEAU.blocs = {}
    NIVEAU.tailleX = 0
    local y = 1
    for line in love.filesystem.lines(path) do
        NIVEAU.blocs[y] = {}
        for x = 1, #line do
            local caractere = line:sub(x, x)
            if caractere == "x" then
                NIVEAU.blocs[y][x] = 1
            elseif caractere == "j" then
                -- TODO position des autres joueurs?
                JOUEURS[#JOUEURS + 1] = {
                    x = x,
                    y = y,
                    vx = 0,
                    vy = 0,
                    vivant = true,
                    tailleX = 1.2,
                    tailleY = 1.2,
                    image = IMAGES.joueur,
                    joystick = nil
                }
            elseif caractere == "m" then
                MONSTRES[#MONSTRES + 1] = {
                    x = x,
                    y = y,
                    vx = 0,
                    vy = 0,
                    vivant = true,
                    tailleX = 0.8,
                    tailleY = 0.8,
                    image = IMAGES.monstre
                }
            else
                NIVEAU.blocs[y][x] = 0
            end
            NIVEAU.tailleX = math.max(NIVEAU.tailleX, x)
        end
        y = y + 1
    end
end

function signe(nombre)
    if nombre < 0 then
        return -1
    elseif nombre > 0 then
        return 1
    else
        return 0
    end
end
