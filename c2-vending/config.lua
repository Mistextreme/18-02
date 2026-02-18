Config = {}

-- ===============================
-- MONEY
-- ===============================
Config.Account = 'cash' -- cash / bank

Config.Cooldown = 3000

-- ===============================
-- VENDING MACHINES (ONLY POSITION)
-- ===============================
Config.Machines = {
    {
        coords = vec3(1142.05, -978.81, 46.29),
        heading = 46.29
    },
    {
        coords = vec3(-1103.99, 2697.94, 18.67),
        heading = 42.28
    },
        {
        coords = vec3(-2072.7, -319.48, 13.32),
        heading = 261.5
    },
    {
        coords = vec3(-47.3, -1757.6, 29.4),
        heading = 45.0
    }
}

-- ===============================
-- ITEMS SHOWN IN NUI (GLOBAL)
-- ===============================
Config.VendingItems = {
    { item = "water", label = "Water Bottle", price = 15, icon = "assets/water.png" },
    { item = "cola",  label = "Cola",         price = 15, icon = "assets/cola.png"  },
    { item = "sandwich", label = "Sandwich",  price = 20, icon = "assets/burger.png"}
}

-- ===============================
-- VISUAL PROPS FOR DROPS
-- ===============================
Config.ItemProps = {
    water     = `prop_ld_flow_bottle`,
    cola      = `prop_ecola_can`,
    sandwich  = `prop_sandwich_01`
}