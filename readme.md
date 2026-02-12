# Install – Items and images

## Item definitions

Add these to your inventory. Stash props are useable: using the item starts placement mode.

### ox_inventory (`ox_inventory/data/items.lua` or your items file)

```lua
['prop_fridge_0206'] = {
    label = 'Fridge 0206',
    weight = 5000,
    stack = false,
    close = true,
},

['prop_side_refri'] = {
    label = 'Side Fridge',
    weight = 6000,
    stack = false,
    close = true,
},

['prop_ai_lg_'] = {
    label = 'Luxury Fridge',
    weight = 7000,
    stack = false,
    close = true,
},

['prop_wardrobe_02'] = {
    label = 'Wardrobe 02',
    weight = 8000,
    stack = false,
    close = true,
},

['prop_wardrobe_elegance'] = {
    label = 'Elegant Wardrobe',
    weight = 9000,
    stack = false,
    close = true,
},

['propwoodwardrobe'] = {
    label = 'Wood Wardrobe',
    weight = 8500,
    stack = false,
    close = true,
},
```


### qb-inventory (e.g. `qb-core/shared/items.lua`)

Add the entries from `install/qb-inventory_items.lua` into your items table. The resource registers these as useable for QB.

```lua
['prop_fridge_0206'] = {
    ['name'] = 'prop_fridge_0206',
    ['label'] = 'Fridge 0206',
    ['weight'] = 5000,
    ['type'] = 'item',
    ['image'] = 'prop_fridge_0206.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable fridge stash'
},
['prop_side_refri'] = {
    ['name'] = 'prop_side_refri',
    ['label'] = 'Side Fridge',
    ['weight'] = 6000,
    ['type'] = 'item',
    ['image'] = 'prop_side_refri.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable side fridge stash'
},
['prop_ai_lg_'] = {
    ['name'] = 'prop_ai_lg_',
    ['label'] = 'Luxury Fridge',
    ['weight'] = 7000,
    ['type'] = 'item',
    ['image'] = 'prop_ai_lg_.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable luxury fridge stash'
},
['prop_wardrobe_02'] = {
    ['name'] = 'prop_wardrobe_02',
    ['label'] = 'Wardrobe 02',
    ['weight'] = 8000,
    ['type'] = 'item',
    ['image'] = 'prop_wardrobe_02.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable wardrobe stash'
},
['prop_wardrobe_elegance'] = {
    ['name'] = 'prop_wardrobe_elegance',
    ['label'] = 'Elegant Wardrobe',
    ['weight'] = 9000,
    ['type'] = 'item',
    ['image'] = 'prop_wardrobe_elegance.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable elegant wardrobe stash'
},
['propwoodwardrobe'] = {
    ['name'] = 'propwoodwardrobe',
    ['label'] = 'Wood Wardrobe',
    ['weight'] = 8500,
    ['type'] = 'item',
    ['image'] = 'propwoodwardrobe.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Placeable wood wardrobe stash'
},
```

## Images

Copy from `install/images/` to your inventory images folder:

- **ox_inventory:** `ox_inventory/web/images/`
- **qs-inventory:** `qs-inventory/html/images/`
- **qb-inventory:** `qb-inventory/html/images/`

## Config

`shared/config.lua`
