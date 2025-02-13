Config = {}

Config.ChanceToBeHostile = 40 -- % chance that ped will be hostile
Config.ChanceToHaveWeapon = 20 -- % chance that hostile ped has a weapon
Config.MinCash = 50
Config.MaxCash = 500

Config.Items = {
    {
        name = "phone",
        min = 1,
        max = 1,
        chance = 40
    },
    {
        name = "water",
        min = 1,
        max = 3,
        chance = 60
    },
    {
        name = "burger",
        min = 1,
        max = 2,
        chance = 50
    },
    -- Füge weitere Items hinzu
}

Config.WeaponsList = {
    "WEAPON_KNIFE",
    "WEAPON_PISTOL",
    -- Füge weitere Waffen hinzu
}

Config.Texts = {
    English = {
        HostileNPCAttacking = "The NPC is attacking you!",
        HostileNPCFighting = "The NPC is fighting back!",
        RobberyCooperating = "The NPC is cooperating...",
        LootAvailableMoney = "Money has been dropped!",
        LootAvailableItems = "Items have been dropped!",
        CleanedUpStash = "Cleaned up empty stash:",
        FailedToAddMoney = "Failed to add money to stash",
        FailedToAddItem = "Failed to add %s to stash",
        AddedMoneyToStash = "Added money to stash:",
        AddedItemToStash = "Added %d %s to stash",
        CreatedStash = "Created stash:",
        ErrorInCreateDropStash = "Error in CreateDropStash:",
        CleaningUpAllStashes = "Cleaning up all stashes...",
        PressToOpenLoot = "Press ~INPUT_CONTEXT~ to open loot",
        MoneyDrop = "💰 Money Drop",
        ItemsDrop = "📦 Items Drop"
    },
    German = {
        HostileNPCAttacking = "Der NPC greift dich an!",
        HostileNPCFighting = "Der NPC wehrt sich!",
        RobberyCooperating = "Der NPC kooperiert...",
        LootAvailableMoney = "Geld wurde fallen gelassen!",
        LootAvailableItems = "Gegenstände wurden fallen gelassen!",
        CleanedUpStash = "Leeres Versteck aufgeräumt:",
        FailedToAddMoney = "Fehler beim Hinzufügen von Geld zum Versteck",
        FailedToAddItem = "Fehler beim Hinzufügen von %s zum Versteck",
        AddedMoneyToStash = "Geld zum Versteck hinzugefügt:",
        AddedItemToStash = "%d %s zum Versteck hinzugefügt",
        CreatedStash = "Versteck erstellt:",
        ErrorInCreateDropStash = "Fehler in CreateDropStash:",
        CleaningUpAllStashes = "Alle Verstecke aufräumen...",
        PressToOpenLoot = "Drücke ~INPUT_CONTEXT~, um die Beute zu öffnen",
        MoneyDrop = "💰 Geldabwurf",
        ItemsDrop = "📦 Gegenstandsabwurf"
    }
}

return Config
