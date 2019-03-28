local customEnabled = true;

LoadAddOn("Blizzard_ItemAlterationUI");

local bor, band, lshift = bit.bor, bit.band, bit.lshift;
local NUM_BAG_SLOTS, BACKPACK_CONTAINER, BANK_CONTAINER = _G.NUM_BAG_SLOTS, _G.BACKPACK_CONTAINER, _G.BANK_CONTAINER;
local ITEM_QUALITY_LEGENDARY = ITEM_QUALITY_LEGENDARY;

local equipLocation =
{
    INVTYPE_HEAD 		= 1,
    INVTYPE_SHOULDER	= 3,
    INVTYPE_BODY		= 4,
    INVTYPE_CHEST		= 5,
    INVTYPE_WAIST		= 6,
    INVTYPE_LEGS		= 7,
    INVTYPE_FEET		= 8,
    INVTYPE_WRIST		= 9,
    INVTYPE_HAND		= 10,
    INVTYPE_BACK		= 15,
    INVTYPE_MAINHAND	= 16,
    INVTYPE_OFFHAND		= 17,
    INVTYPE_RANGED		= 18,
};

-- location offsets
local ITEM_INVENTORY_BAG_BIT_OFFSET   = ITEM_INVENTORY_BAG_BIT_OFFSET;
local ITEM_INVENTORY_LOCATION_BAGS    = ITEM_INVENTORY_LOCATION_BAGS;
local ITEM_INVENTORY_LOCATION_BANK    = ITEM_INVENTORY_LOCATION_BANK;
local ITEM_INVENTORY_LOCATION_PLAYER  = ITEM_INVENTORY_LOCATION_PLAYER;
local ITEM_INVENTORY_LOCATION_VOIDSTORAGE   = ITEM_INVENTORY_LOCATION_VOIDSTORAGE;

function PackInventoryLocation(container, slot, equipment, bank, bags, voidStorage)
	local location = 0
	-- basic flags
    location = bor(location, equipment      and ITEM_INVENTORY_LOCATION_PLAYER or 0);
    location = bor(location, bags           and ITEM_INVENTORY_LOCATION_BAGS or 0);
	location = bor(location, bank           and ITEM_INVENTORY_LOCATION_BANK or 0);
	location = bor(location, voidStorage    and ITEM_INVENTORY_LOCATION_VOIDSTORAGE or 0);

	-- container (tab, bag, ...) and slot
	location = location + (slot or 1)
	
    if bank and bags and container > NUM_BAG_SLOTS then
		-- store bank bags as 1-7 instead of 5-11
		container = container - ITEM_INVENTORY_BANK_BAG_OFFSET;
	end
    
    if container and container > 0 then
		location = location + lshift(container, ITEM_INVENTORY_BAG_BIT_OFFSET)
	end

    -- TODO: FIX BANK!!
    if bank and not bags then
        location = location + 39;
    end

	return location;
end

local function AddEquippableItem(useTable, inventorySlot, container, slot)
    local itemID = GetContainerItemID(container, slot)
	local link   = GetContainerItemLink(container, slot)
        
    if not link then return end
    
	local isBags   = container >= BACKPACK_CONTAINER and container <= NUM_BAG_SLOTS + _G.NUM_BANKBAGSLOTS
	local isBank   = container == BANK_CONTAINER or (isBags and container > NUM_BAG_SLOTS)
	local isPlayer = not isBank
	if not isBags then container = nil end

	local location = PackInventoryLocation(container, slot, isPlayer, isBank, isBags);
    
	local _, _, _, _, _, _, subClass, _, equipSlot = GetItemInfo(link)
    
    if equipLocation[equipSlot] == inventorySlot and useTable[location] == nil then
        useTable[location] = itemID;
	end
end

hooksecurefunc('GetInventoryItemsForSlot', function(inventorySlot, useTable, transmog)
    if transmog == nil then return end
    
    local _, _, _, _, _, _, mainItemSubClass, _, mies = GetItemInfo(GetInventoryItemID("player", inventorySlot));
    
    if mainItemSubClass == nil then return end
    
    if customEnabled == true then
        for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(container) do
                AddEquippableItem(useTable, inventorySlot, container, slot)
            end
        end
        
        --print(PackInventoryLocation(BANK_CONTAINER, 2, nil, true, nil));
        
        -- scan bank main frame (data is only available when bank is opened)
        for slot = 1, _G.NUM_BANKGENERIC_SLOTS do
            AddEquippableItem(useTable, inventorySlot, BANK_CONTAINER, slot)
        end
        
        -- scan bank containers
        for bankContainer = 1, _G.NUM_BANKBAGSLOTS do
            local container = _G.ITEM_INVENTORY_BANK_BAG_OFFSET + bankContainer
            for slot = 1, GetContainerNumSlots(container) or 0 do
                AddEquippableItem(useTable, inventorySlot, container, slot)
            end
        end
    else
        for location, itemId in pairs(useTable) do
            local _, _, itemRarity, _, _, _, itemSubClass  = GetItemInfo(itemId);
            
            if itemRarity == ITEM_QUALITY_LEGENDARY or (mainItemSubClass ~= itemSubClass
                and mies ~= "INVTYPE_2HWEAPON" and mies ~= "INVTYPE_WEAPONMAINHAND" and mies ~= "INVTYPE_WEAPONOFFHAND" and mies ~= "INVTYPE_HOLDABLE" and mies ~= "INVTYPE_RANGED" and mies ~= "INVTYPE_RANGEDRIGHT") then
                useTable[location] = nil;
            end
        end
    end
end)

hooksecurefunc('TransmogrifyFrame_UpdateApplyButton', function()
    --MoneyFrame_Update("TransmogrifyMoneyFrame", 111111);
end)
