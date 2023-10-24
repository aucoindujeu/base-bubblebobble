local Timer = require "lib.knife.timer"
local push = require "lib.push"

-- Variables qu'on peut modifier pour changer le gameplay ou l'apparence du jeu
NOM = "xxxxxxxxx"
GRAVITE = 9.81 * 7
VENT = 0
JOUEUR_VITESSE = 8
JOUEUR_VITESSE_SAUT = 20
JOUEUR_TAILLE = 0.9
MONSTRES_VITESSE = JOUEUR_VITESSE * 0.5
MONSTRES_TAILLE = 0.8
VITESSE_CHUTE_MAX = 10
ECHELLE_DESSIN = 50
LARGEUR_JEU = 800
HAUTEUR_JEU = 600
TYPO = love.graphics.newFont("typos/retro.ttf", 64)

-- Ne pas modifier ces variables
NIVEAU_ACTUEL = 0
MENU_JOUEUR_SELECTIONNE = 1
NIVEAU = {}
JOUEURS = {}
MONSTRES = {}
ControleurFleches = {
    nom = "LR",
    id = "LR"
}
ControleurAD = {
    nom = "ZAD",
    id = "ZAD"
}
ControleurJoystick = {}
CONTROLEURS = {}
TOUCHES_PRESSEES = {}

-- Ne pas modifier ces variables, mais directement les fichiers
IMAGES = {
    joueur = love.graphics.newImage("images/joueur.png"),
    bloc = love.graphics.newImage("images/bloc.png"),
    monstre = love.graphics.newImage("images/monstre.png")
}
SONS = {
    defaite = love.audio.newSource("sons/defaite.mp3", "static"),
    mort = love.audio.newSource("sons/mort.mp3", "static"),
    saut = love.audio.newSource("sons/saut.mp3", "static"),
    victoire = love.audio.newSource("sons/victoire.mp3", "static"),
    musique_debut = love.audio.newSource("sons/musique-debut.mp3", "stream")
}

EtatActuel = nil
EtatDebut = {}
EtatNiveauSuivant = {}
EtatCombat = {}
EtatDefaite = {}
EtatVictoire = {}

function love.load()
    love.window.setTitle(NOM)
    love.graphics.setFont(TYPO)
    love.graphics.setDefaultFilter("nearest", "nearest")
    local largeurFenetre, hauteurFenetre = love.window.getDesktopDimensions()
    push:setupScreen(
        LARGEUR_JEU, HAUTEUR_JEU,
        largeurFenetre, hauteurFenetre,
        { fullscreen = false, resizable = true }
    )

    changerEtat(EtatDebut)
end

function love.update(dt)
    Timer.update(dt)
    if EtatActuel.update then
        EtatActuel:update(dt)
    end
    TOUCHES_PRESSEES = {}
end

function love.draw()
    push:start()
    if EtatActuel.dessiner then
        EtatActuel:dessiner()
    end
    push:finish()
end

function love.resize(largeur, hauteur)
    push:resize(largeur, hauteur)
end

function love.keypressed(touche)
    -- TODO gérer les pauses
    TOUCHES_PRESSEES[touche] = true
    if touche == "escape" then
        -- TODO vraiment?
        love.event.quit()
    end
end

function changerEtat(nouvelEtat)
    if EtatActuel and EtatActuel.sortir then
        EtatActuel:sortir()
    end
    EtatActuel = nouvelEtat
    if EtatActuel.entrer then
        EtatActuel:entrer()
    end
end

function EtatDebut:entrer()
    SONS.musique_debut:play()
    SONS.musique_debut:setLooping(true)
    -- TODO assigner le joystick1 par défaut sur une borne d'arcade
    -- TODO assigner les flèches par défaut sur un clavier
    CONTROLEURS = {}
    MENU_JOUEUR_SELECTIONNE = 1
end

function EtatDebut:update(dt)
    -- Selection du joueur
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepadDown("a", "b") then
            local id = joystick:getID()
            if controleurDisponible(id) then
                -- TODO Ca c'est VRAIMENT moche.
                local controleur = {
                    id = id,
                    nom = "JOY", -- TODO ajouter le nom de la manette?
                    joystick = joystick,
                    directionX = ControleurJoystick.directionX,
                    saut = ControleurJoystick.saut
                }
                CONTROLEURS[#CONTROLEURS + 1] = controleur
                joystick:setVibration(1, 1)
                Timer.after(0.1, function() joystick:setVibration(0, 0) end)
            end
        end
    end
    if TOUCHES_PRESSEES["space"] or TOUCHES_PRESSEES["rctrl"] then
        -- Est-ce que les flèches sont disponibles ?
        if controleurDisponible(ControleurFleches.id) then
            CONTROLEURS[#CONTROLEURS + 1] = ControleurFleches
        end
    end
    if TOUCHES_PRESSEES["a"] or TOUCHES_PRESSEES["q"] or TOUCHES_PRESSEES["z"] or TOUCHES_PRESSEES["s"] or TOUCHES_PRESSEES["d"] then
        -- Est-ce que les flèches sont disponibles ?
        if controleurDisponible(ControleurAD.id) then
            CONTROLEURS[#CONTROLEURS + 1] = ControleurAD
        end
    end

    -- On part au combat
    local appuieStart = TOUCHES_PRESSEES["return"]
    for _, joystick in ipairs(love.joystick:getJoysticks()) do
        if joystick:isGamepadDown("start") then
            appuieStart = true
        end
    end
    if #CONTROLEURS > 0 and appuieStart then
        changerEtat(EtatNiveauSuivant)
    end
end

function controleurDisponible(id)
    -- retourne true si le controleur peut être assigné à un joueur
    if #CONTROLEURS == 4 then
        -- Seulement quatre joueurs supportés...
        return false
    end
    for _, controleur in ipairs(CONTROLEURS) do
        if controleur.id == id then
            return false
        end
    end
    return true
end

function EtatDebut:dessiner()
    love.graphics.setColor(1, 1, 0)
    ecrire(NOM, LARGEUR_JEU / 2, HAUTEUR_JEU * 0.3, 2)
    love.graphics.setColor(1, 1, 1)
    if #CONTROLEURS > 0 then
        for c, controleur in ipairs(CONTROLEURS) do
            love.graphics.setColor(1, 1, 1)
            ecrire(
                string.format("player %d - %s", c, controleur.nom),
                LARGEUR_JEU / 2, HAUTEUR_JEU * (0.5 + c * 0.05),
                0.3
            )
        end
        ecrire("press start", LARGEUR_JEU / 2, HAUTEUR_JEU * 0.8, 0.5)
    else
        love.graphics.setColor(1, 1, 1)
        ecrire("en attente de joueurs...", LARGEUR_JEU / 2, HAUTEUR_JEU * 0.8, 0.3)
    end
    for c = #CONTROLEURS + 1, 4 do
        love.graphics.setColor(0.5, 0.5, 0.5)
        ecrire(
            string.format("player %d", c),
            LARGEUR_JEU / 2, HAUTEUR_JEU * (0.5 + c * 0.05),
            0.3
        )
    end
end

function EtatDebut:sortir()
    SONS.musique_debut:stop()
    NIVEAU_ACTUEL = 0
end

function EtatNiveauSuivant:entrer()
    NIVEAU_ACTUEL = NIVEAU_ACTUEL + 1

    local fichierNiveau = string.format("niveaux/niveau-%03d.txt", NIVEAU_ACTUEL)
    local niveauInfo = love.filesystem.getInfo(fichierNiveau)
    if not niveauInfo then
        -- On a fait le dernier niveau !
        changerEtat(EtatVictoire)
    else
        -- On part au combat...
        chargerNiveau(fichierNiveau)
        Timer.after(2, function() changerEtat(EtatCombat) end)
    end
end

function EtatNiveauSuivant:dessiner()
    love.graphics.setColor(1, 1, 1)
    ecrire(
        string.format("Level %d", NIVEAU_ACTUEL),
        LARGEUR_JEU / 2,
        HAUTEUR_JEU * 0.4,
        1
    )
end

function chargerNiveau(path)
    JOUEURS = {}
    NIVEAU = {}
    MONSTRES = {}
    NIVEAU.blocs = {}
    NIVEAU.tailleX = 0
    local y = 1
    for line in love.filesystem.lines(path) do
        NIVEAU.blocs[y] = {}
        for x = 1, #line do
            local caractere = line:sub(x, x)
            if caractere == "x" then
                NIVEAU.blocs[y][x] = 1
            elseif caractere == "j" and #CONTROLEURS > #JOUEURS then
                -- TODO position des autres joueurs?
                JOUEURS[#JOUEURS + 1] = {
                    x = x,
                    y = y,
                    vx = 0,
                    vy = 0,
                    vivant = true,
                    tailleX = JOUEUR_TAILLE,
                    tailleY = JOUEUR_TAILLE,
                    image = IMAGES.joueur,
                    controleur = CONTROLEURS[#JOUEURS + 1]
                }
            elseif caractere == "m" then
                MONSTRES[#MONSTRES + 1] = {
                    x = x,
                    y = y,
                    vx = 0,
                    vy = 0,
                    vivant = true,
                    tailleX = MONSTRES_TAILLE,
                    tailleY = MONSTRES_TAILLE,
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

function EtatCombat:update(dt)
    -- Calcul des vitesses
    for _, joueur in ipairs(JOUEURS) do
        if joueur.vivant then
            calculerVitesseJoueur(joueur, dt)
        end
    end
    for _, monstre in ipairs(MONSTRES) do
        if monstre.vivant then
            calculerVitesseMonstre(monstre, dt)
        end
    end

    -- Collision entre les joueurs et les monstres
    for _, joueur in ipairs(JOUEURS) do
        if joueur.vivant then
            for _, monstre in ipairs(MONSTRES) do
                if monstre.vivant then
                    -- si le joueur va rentrer en collision avec le monstre et que les pieds
                    -- du joueur étaient au dessus de la tête du monstre, alors on a tué le monstre
                    if joueur.vy > 0 and testCollision(
                            joueur.x + joueur.vx * dt, joueur.y + joueur.vy * dt,
                            joueur.tailleX, joueur.tailleY,
                            monstre.x, monstre.y,
                            monstre.tailleX, monstre.tailleY
                        ) and joueur.y + joueur.tailleY / 2 < monstre.y - monstre.tailleY / 2 then
                        -- Monstre écrasé !
                        Timer.after(1 / 12, function()
                            monstre.tailleY = monstre.tailleY / 2
                            monstre.y = monstre.y + monstre.tailleY * 3 / 4
                        end)
                        Timer.after(2 / 12, function() monstre.tailleY = 0 end)
                        monstre.vivant = false
                    elseif testCollision(
                            joueur.x, joueur.y,
                            joueur.tailleX, joueur.tailleY,
                            monstre.x, monstre.y,
                            monstre.tailleX, monstre.tailleY
                        ) then
                        -- Joueur mort !
                        joueur.vivant = false
                        Timer.tween(1, {
                            -- on rend le joueur tout petit
                            [joueur] = { tailleX = 0, tailleY = 0 }
                        })
                        SONS.mort:play()
                    end
                end
            end
        end
    end

    -- Déplacements
    local joueursVivants = 0
    for _, joueur in ipairs(JOUEURS) do
        if joueur.vivant then
            joueursVivants = joueursVivants + 1
            deplacerObjet(joueur, dt)
        end
    end
    local monstresVivants = 0
    for _, monstre in ipairs(MONSTRES) do
        if monstre.vivant then
            monstresVivants = monstresVivants + 1
            deplacerObjet(monstre, dt)
        end
    end

    if joueursVivants == 0 then
        -- TODO game over
        Timer.after(2, function() changerEtat(EtatDefaite) end)
    elseif monstresVivants == 0 then
        -- victoire ! niveau suivant
        SONS.victoire:play()
        Timer.after(2, function() changerEtat(EtatNiveauSuivant) end)
    end
end

function calculerVitesseMonstre(monstre, dt)
    if monstre.vx == 0 and testObjetSurLeSol(monstre) then
        -- quand le monstre est sur le sol avec une vitesse horizontale nulle, on le
        -- fait se déplacer dans une direction au hasard
        monstre.vx = (math.random(0, 1) * 2 - 1) * MONSTRES_VITESSE
    end
    local directionInitiale = signe(monstre.vx)

    calculerVitesse(monstre, dt)

    if directionInitiale ~= 0 and monstre.vx == 0 then
        -- le monstre a fait une collision, on change de direction
        monstre.vx = -directionInitiale * MONSTRES_VITESSE
    end
end

function calculerVitesseJoueur(joueur, dt)
    -- Déplacement à gauche et à droite
    joueur.vx = joueur.controleur:directionX() * JOUEUR_VITESSE

    -- saut
    if joueur.controleur:saut() and testObjetSurLeSol(joueur) then
        -- TODO comment sauter plus haut en fonction de la durée pendant laquelle on appuie?
        joueur.vy = -JOUEUR_VITESSE_SAUT
        SONS.saut:play()
    end

    calculerVitesse(joueur, dt)
end

function calculerVitesse(objet, dt)
    -- On applique la gravité
    objet.vy = objet.vy + GRAVITE * dt

    -- Vitesse de chute à ne pas dépasser
    if objet.vy > VITESSE_CHUTE_MAX then
        objet.vy = VITESSE_CHUTE_MAX
    end

    -- collisions avec les blocs
    for y, ligne in ipairs(NIVEAU.blocs) do
        for x, bloc in ipairs(ligne) do
            if bloc == 1 then
                -- est-ce qu'il y a collision ?
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
    local solY = objet.y + objet.tailleY / 2 + 1 / 2
    if solY < 1 or solY > #NIVEAU.blocs or solY ~= math.floor(solY) then
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

function EtatCombat:dessiner()
    dessinerNiveau()
    for _, monstre in ipairs(MONSTRES) do
        dessinerObjet(monstre)
    end
    for _, joueur in ipairs(JOUEURS) do
        dessinerObjet(joueur)
    end
end

function dessinerNiveau()
    for y = 1, #NIVEAU.blocs do
        for x = 1, #NIVEAU.blocs[y] do
            if NIVEAU.blocs[y][x] == 1 then
                dessinerImage(x, y, 1, 1, IMAGES.bloc)
            end
        end
    end
end

function dessinerObjet(objet)
    dessinerImage(objet.x, objet.y, objet.tailleX, objet.tailleY, objet.image)
end

function dessinerImage(x, y, tailleX, tailleY, image)
    local echelle = math.min(LARGEUR_JEU / NIVEAU.tailleX, HAUTEUR_JEU / #NIVEAU.blocs)
    local offsetX = (LARGEUR_JEU - NIVEAU.tailleX * echelle) / 2
    local offsetY = (HAUTEUR_JEU - #NIVEAU.blocs * echelle) / 2
    love.graphics.draw(
        image,
        (x - 1 - tailleX / 2) * echelle + offsetX,
        (y - 1 - tailleY / 2) * echelle + offsetY,
        0,                                      -- orientation
        (tailleX / image:getWidth()) * echelle, -- scaleX
        (tailleY / image:getHeight()) * echelle -- scaleY
    )
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

function EtatDefaite:entrer(dt)
    SONS.defaite:play()
end

function EtatDefaite:update(dt)
    local appuieStart = TOUCHES_PRESSEES["space"]
    if TOUCHES_PRESSEES["return"] then
        appuieStart = true
    end
    for _, joystick in ipairs(love.joystick:getJoysticks()) do
        if joystick:isGamepadDown("start") then
            appuieStart = true
        end
    end
    if appuieStart then
        changerEtat(EtatDebut)
    end
end

function EtatDefaite:dessiner()
    love.graphics.setColor(1, 1, 1)
    ecrire("Game\nOver", LARGEUR_JEU / 2, HAUTEUR_JEU * 0.3, 2)
    ecrire("appuie sur espace", LARGEUR_JEU / 2, HAUTEUR_JEU * 0.8, 0.5)
end

function EtatVictoire:dessiner()
    love.graphics.setColor(1, 1, 1)
    ecrire("gg!", LARGEUR_JEU / 2, HAUTEUR_JEU / 2, 5)
end

function EtatVictoire:update(dt)
    -- TODO code dupliqué de EtatDefaite et EtatDebut
    local appuieStart = TOUCHES_PRESSEES["space"]
    if TOUCHES_PRESSEES["return"] then
        appuieStart = true
    end
    for _, joystick in ipairs(love.joystick:getJoysticks()) do
        if joystick:isGamepadDown("start") then
            appuieStart = true
        end
    end
    if appuieStart then
        changerEtat(EtatDebut)
    end
end

function ecrire(texte, x, y, echelle)
    local largeur = TYPO:getWidth(texte) * echelle
    local hauteur = TYPO:getHeight() * echelle
    love.graphics.print(
        texte,
        x - largeur / 2,
        y - hauteur / 2,
        0,
        echelle, echelle
    )
end

function ControleurFleches:directionX()
    local dirX = 0
    if love.keyboard.isDown("left") then
        dirX = dirX - 1
    end
    if love.keyboard.isDown("right") then
        dirX = dirX + 1
    end
    return dirX
end

function ControleurFleches:saut()
    return TOUCHES_PRESSEES["rctrl"] or TOUCHES_PRESSEES["space"]
end

function ControleurAD:directionX()
    local dirX = 0
    if love.keyboard.isDown("q") or love.keyboard.isDown("a") then
        dirX = dirX - 1
    end
    if love.keyboard.isDown("d") then
        dirX = dirX + 1
    end
    return dirX
end

function ControleurAD:saut()
    return TOUCHES_PRESSEES["lshift"]
end

function ControleurJoystick.directionX(controleur)
    local dirX = controleur.joystick:getGamepadAxis("leftx")
    if math.abs(dirX) < 0.2 then
        -- on limite les petits déplacements
        dirX = 0
    end
    return dirX
end

function ControleurJoystick.saut(controleur)
    return controleur.joystick:isGamepadDown("a", "b")
end

