function love.load()
    local longueurFenetre, hauteurFenetre = love.window.getDesktopDimensions()
    love.window.setMode(longueurFenetre, hauteurFenetre)

    GRAVITE = 600
    VENT = 0
    monde = love.physics.newWorld(VENT, GRAVITE)
    -- monde:setCallbacks("contact", "finContact")

    joueur = {
        debut_x = 0,
        debut_y = 0,
        longueur = 50,
        hauteur = 100,
        vitesse = 500,
        forceSaut = -250,
        image = love.graphics.newImage("images/rien.png"),
        hitbox = nil,
        surLeSol = false
    }
    joueur.hitbox = creerHitbox(joueur.debut_x, joueur.debut_y, joueur.longueur, joueur.hauteur, "dynamic")
    joueur.hitbox.corps:setFixedRotation(true)

    niveau = creerNiveaux("niveaux/niveau_1.txt")

    tailleBlock = 50
    blocks = {}

    for y, v in ipairs(niveau) do
        for x, w in ipairs(v) do
            if w == 1 then
                table.insert(blocks, creerHitbox(x * tailleBlock, y * tailleBlock, tailleBlock, tailleBlock, "static"))
            end
        end
    end
end

function love.update(dt)
    -- joueur.surLeSol = false
    -- local x, y = coordonnees(joueur.hitbox)
    -- y = y + joueur.h / 2 + 1
    -- if niveau[]

    bougerJoueur(dt)
    monde:update(dt)
end

function bougerJoueur(dt)
    -- bouger à gauche et à droite
    local vx = 0
    if love.keyboard.isDown("right") then
        vx = joueur.vitesse
    end
    if love.keyboard.isDown("left") then
        vx = -joueur.vitesse
    end
    local _, vy = joueur.hitbox.corps:getLinearVelocity()
    
    -- saut
    if love.keyboard.isDown("space") then
        local vx, _ = joueur.hitbox.corps:getLinearVelocity()
        joueur.hitbox.corps:setLinearVelocity(vx, joueur.forceSaut)
    end
    joueur.hitbox.corps:setLinearVelocity(vx, vy)
end

function love.draw()
    love.graphics.draw(joueur.image, joueur.hitbox.corps:getX() - joueur.longueur / 2, joueur.hitbox.corps:getY() - joueur.hauteur / 2, 0,
                        joueur.longueur / joueur.image:getWidth(),
                        joueur.hauteur / joueur.image:getHeight())

    for i,v in ipairs(blocks) do
        love.graphics.draw(joueur.image, v.corps:getX() - tailleBlock / 2, v.corps:getY() - tailleBlock / 2)
    end
end

function love.keypressed(touche)
    if touche == "escape" then
        love.event.quit()
    elseif touche == "space" then
        local vx, _ = joueur.hitbox.corps:getLinearVelocity()
        joueur.hitbox.corps:setLinearVelocity(vx, joueur.forceSaut)
    end
end

function coordonnees(hitbox)
    return hitbox.corps:getX(), hitbox.corps:getY()
end

function creerHitbox(x, y, l, h, type, data)
    local hitbox = {
        l = l,
        h = h,
        corps = love.physics.newBody(monde, x, y, type),
        forme = love.physics.newRectangleShape(l, h)
    }
    hitbox.fixture = love.physics.newFixture(hitbox.corps, hitbox.forme, 1)
    hitbox.fixture:setUserData(data)

    return hitbox
end

function creerNiveaux(path)
    local niveau = {}
    local y = 1
    for line in io.lines(path) do
        niveau[y] = {}
        for x = 1, #line do
            local s = line:sub(x, x)
            if s == "x" then
                niveau[y][x] = 1
            else
                niveau[y][x] = 0
            end
        end
        y = y + 1
    end

    return niveau
end
