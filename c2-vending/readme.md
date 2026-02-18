# on top of all this ox_inventory/data/shops.lua
local enableVending = false 


# all the way down replace this vending block

	VendingMachineDrinks = enableVending and {
		name = 'Vending Machine',
		inventory = {
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
		},
		model = {
			`prop_vend_soda_02`, `prop_vend_fridge01`, `prop_vend_water_01`, `prop_vend_soda_01`
		}
	} or nil