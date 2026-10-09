-- Prices, and the bundle each tower is built from. Damage, range and the rest are
-- properties of the Tower script on each bundle.

return {
    ballista = { name = "Ballista", bundle = "bundles/Ballista", cost = 60, upgrades = { 50, 90 } },
    cannon = { name = "Cannon", bundle = "bundles/Cannon", cost = 110, upgrades = { 90, 150 } },
    frost = { name = "Frost Tower", bundle = "bundles/FrostTower", cost = 85, upgrades = { 70, 120 } },
}
