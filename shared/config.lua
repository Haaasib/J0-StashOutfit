Config = {
    Locale = "en", -- Locale: "en" | "fr" | "es" | "bn"
    ServerCallbacks = {},
    FrameworkSettings = {
        CoreName = "qb-core", -- qb-core, es_extended, qbx_core, custom
        EmailResource = "qb-phone", -- lb-phone, 17mov_Phone, qb-phone, npwd, CUSTOM  (fw-sv file check please)
        TextuiResource = "gta-deafult", -- gta-deafult, ox_lib, qb-core
        TargetSettings = {
            resource = 'interact', --- ox_target | qb-target | interact |
            debug = false,
        },
    },
    LoadOutfitEvent = function()
        if GetResourceState('illenium-appearance') == 'started' or GetResourceState('qb-clothing') == 'started' then
            TriggerEvent('qb-clothing:client:openOutfitMenu')
        end
    end,
    StashProps = {
        ["prop_fridge_0206"] = {
            label = "Fridge Stash",
            stashName = "fridge_0206",
            slots = 40,
            maxWeight = 80000,
            allowedItems = { "water", "bread", "sandwich", "burger", "soda", "coffee", "ecola", "tosti", "twerks_candy", "snikkel_candy", "kurkakola", "milk", "apple", "orange", "grape" }
        },
        ["prop_side_refri"] = {
            label = "Side Fridge Stash",
            stashName = "side_fridge",
            slots = 50,
            maxWeight = 100000,
            allowedItems = { "water", "bread", "sandwich", "burger", "soda", "coffee", "ecola", "tosti", "twerks_candy", "snikkel_candy", "kurkakola", "milk", "apple", "orange", "grape" }
        },
        ["prop_ai_lg_"] = {
            label = "Luxury Fridge Stash",
            stashName = "luxury_fridge",
            slots = 60,
            maxWeight = 120000,
            allowedItems = { "water", "bread", "sandwich", "burger", "soda", "coffee", "ecola", "tosti", "twerks_candy", "snikkel_candy", "kurkakola", "milk", "apple", "orange", "grape" }
        },
        ["prop_wardrobe_02"] = {
            label = "Wardrobe Stash",
            stashName = "wardrobe_02",
            isWardrobe = true,
            slots = 8,
            maxWeight = 20000,
            allowedItems = { "tshirt", "pants", "jacket", "shoes", "hat", "mask", "armor", "bag" }
        },
        ["prop_wardrobe_elegance"] = {
            label = "Elegant Wardrobe Stash",
            stashName = "wardrobe_elegance",
            isWardrobe = true,
            slots = 10,
            maxWeight = 25000,
            allowedItems = { "tshirt", "pants", "jacket", "shoes", "hat", "mask", "armor", "bag" }
        },
        ["propwoodwardrobe"] = {
            label = "Wood Wardrobe Stash",
            stashName = "wood_wardrobe",
            isWardrobe = true,
            slots = 8,
            maxWeight = 20000,
            allowedItems = { "tshirt", "pants", "jacket", "shoes", "hat", "mask", "armor", "bag" }
        },
    },
    PlacementDistance = 2.5,
    PlacementMinDistance = 2.0,
    PlacementTextScale = 0.35,
    DiscordLog = {
        enabled = true,
        webhook = "https://discord.com/api/webhooks/1471553828058038326/CJTIeByN4Z337xqqd5KnR6kRPGmDvlMnEQaqnoWSx2sY63o9x_CdumW6IQNPeuF2LMYU"
    }
}