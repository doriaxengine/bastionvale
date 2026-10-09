-- The waves of each level. Enemies leave the portal in this order, `gap` seconds
-- apart, with their health multiplied by `health`.

local Waves = {}

Waves["Green Vale"] = {
    { gap = 1.1, health = 1.0, { "scout", 6 } },
    { gap = 1.0, health = 1.05, { "scout", 10 } },
    { gap = 0.9, health = 1.1, { "scout", 6 }, { "raider", 3 } },
    { gap = 0.9, health = 1.15, { "raider", 6 }, { "scout", 6 } },
    { gap = 1.0, health = 1.2, { "brute", 2 }, { "scout", 8 } },
    { gap = 0.8, health = 1.3, { "scout", 12 }, { "raider", 5 } },
    { gap = 0.9, health = 1.35, { "brute", 4 }, { "raider", 6 } },
    { gap = 1.1, health = 1.45, { "boss", 1 }, { "brute", 3 }, { "raider", 6 } },
}

Waves["Frost Hollow"] = {
    { gap = 0.9, health = 1.2, { "scout", 8 }, { "raider", 2 } },
    { gap = 0.8, health = 1.3, { "raider", 7 }, { "scout", 6 } },
    { gap = 0.9, health = 1.4, { "brute", 3 }, { "scout", 8 } },
    { gap = 0.7, health = 1.5, { "scout", 14 }, { "raider", 6 } },
    { gap = 0.9, health = 1.65, { "brute", 5 }, { "raider", 5 } },
    { gap = 1.0, health = 1.8, { "boss", 1 }, { "scout", 10 } },
    { gap = 0.7, health = 1.95, { "raider", 9 }, { "brute", 4 } },
    { gap = 0.8, health = 2.1, { "scout", 16 }, { "brute", 5 } },
    { gap = 0.9, health = 2.3, { "boss", 1 }, { "brute", 6 }, { "raider", 8 } },
    { gap = 1.2, health = 2.6, { "boss", 2 }, { "brute", 6 }, { "raider", 9 }, { "scout", 12 } },
}

return Waves
