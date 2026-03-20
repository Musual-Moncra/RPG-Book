local GameConfig = {

	-- General
	GameName = "My RPG",
	GameVersion = "v1.0.0", -- Shown faintly at the top center of the screen to identify the server/update version

	XPModifier = "Multiply", -- Set tp "Multiply" if XP goes from 25, 50, 75, 100 w/ default range. Set to "Exponential" if it goes from 5, 25, 125, 625, etc. 
	XPPerLevel = 25, -- The amount of XP needed for each level to level up. With 50, if you're level 5, you need 250 XP to level up to 6 [Reccomended 1.25 for Exponential]

	MaxLevel = math.huge, -- The maximum level you can have before it's capped
	MaxGold = math.huge, -- Implementation from the old kit

	SpawnLocation = Vector3.new(0.494, 1, 35.757), -- Position that TP To Spawn will bring you to, set to nil to use a random SpawnLocation instead

	---- Gameplay configuration

	StarterItems = { -- Starter items that are given to all players
		{"Tool", "Bronze Sword"},
		{"Tool", "Bronze Pickaxe"},
		{"Armor", "Bronze Armor"},
	},

	GlobalDrops = { -- {Type, Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
		{"Tool", "Druid Staff", 1, {1, 15}},
		{"Consumable", "Mana Potion", 1, {1, 25}},
		{"Consumable", "Apple", 1, {1, 10}},
		{"Consumable", "Strength Potion", 1, {1, 10}},
		{"Consumable", "Luck Potion", 1, {1, 1}},
		{"Consumable", "Experience Potion", 1, {1, 1}},
		{"Accessory", "Cerulean Crown", 1, {1, 50}, true},
	},

	DefaultHumanoid = { -- Ported from HumanoidAttributes
		["Health"] = 100,
		["WalkSpeed"] = 16,
		["JumpPower"] = 50,
	},

	Regenerate = {
		["Rate"] = 1 / 100, -- Health per MaxHealth
		["Step"] = 1, -- Seconds duration
	},

	HealthPerLevel = 10, -- Set to 0 to disable
	ManaPerLevel = 10, -- Set to 0 to disable

	---- Multiplier & classes configuration

	ClassBoosts = {"Magic", "Melee", "Ranged", "Mana", "All"}, -- Add a value here to implement new classes (mana & all aren't a class)
	Statistics = {"Defense"}, -- Potion status effect UI

	XPMultiplier = 1,
	GoldMultiplier = 1,

	LuckMultiplier = 1, -- Affects drops and global drops
	CriticalMultiplier = 2, -- Base value is *2

	CriticalChance = {1, 5}, -- random(1, 2)

	MaxDamageInteractions = {20, 5}, -- How many times can the player damage (1) per (2) seconds?
	MaxInputInteractions = {20, 5}, -- Max / time per second for callbacks, keybinds, & blocking / parrying

	---- Interface visibility

	EnabledFeatures = { -- Set to false to both disable visibility for player and disable all serversided aspects
		["AreaProgress"] = true,
		["SpawnedBossUI"] = true,
		["StatChange"] = true,
		["InfoUI"] = true,

		["Attributes"] = true,
		["Crafting"] = true,
		["PawnShop"] = true,
		["BuyShop"] = true,
		["Quests"] = true,
		["Anvil"] = true,
		["Enchants"] = true,

		["ArmorObject"] = true,
		["PlayerHUD"] = true,
		["Props"] = true,
		["ItemIndexes"] = true,
		["MobIndexes"] = true,
	},

	MobHUDStyle = "AtAllTimes", -- None, AtAllTimes, OnlyOnBosses

	DamageCounterPositionIsMob = true, -- Whether damage counter is proportional to the mob or the player's origin of attack
	DamageCounterIsAdditive = true, -- Whether damage counter will add its damage to the previous hit

	ScaleUIs = true, -- If disabled, UIs will not scale based off screen size (fixed size)
	UIScaleClamp = {1, 2}, -- Min, Max * scale of UI

	ScaleMobBarUI = true, -- Disable for the mob UI not to scale based off of defense value
	ScaleAttributesUI = true, -- Disable for the attributes UI not to change based off of script
	MobShowsLevelIfOne = true, -- Enable/disable if the 'shown' mob level is 1, true means it will show at 1

	HideMobHUDIfHeal = true, -- Hides the healthbar & rank if the mob is fully healed (preserves on space)
	ShowMouseCooldownUI = true, -- Small cooldown UI that shows next to the mouse
	ShowPlayerDamageDisplay = true, -- Shows a UI next to the player's health bar if they get damaged

	BackpackEnabled = true, -- I have a remade version of the default backpack I may supply to the kit in the future, don't know yet
	UseToggleInventoryButton = false, -- The [  ^  ] button which is in most kits, removed by default for simplicity (& turned into a slot)
	ShowInventoryBackpackButtonOnPC = true, -- Shows backpack icon on pc if UseToggleInventoryButton is disabled 

	MobileAdaptUI = true, -- UI will slightly change to fit mobile screens better
	MobileShiftLock = true, -- Whether mobile players are given the option to enable shift lock via a UI

	PCAndConsoleMaxSlots = 9, -- Maximum slots for pc/console (non mobile)
	MobileUsesLessSlots = true, -- Toggle for mobile to have 3 hotbar slots (same as regular backpack) to conserve space on player UI

	ServerDropNotifications = true, -- Set to false to disable all drop notifications
	ChanceRequiredToNotifyServer = 1_000, -- Items above this rarity will be notified in the server

	AutoUpdateWalkspeedOnClient = true, -- The client will attempt to automatically update WalkSpeed and JumpPower when attribute values are changed
	MobileBackpackUIScaling = 0.65, -- % of backpack UI scaling does mobile use (set to 1 or nil to disable)

	---- Interface & mob client configuration
	CustomColors = false,
	ColorPreset = "Murasaki", -- Check the ColorPresets for more presets. If you don't want, set this to nil and change the vv below colors

	UIColors = {
		["PrimaryColor"] = Color3.fromRGB(174, 120, 239),
		["SecondaryColor"] = Color3.fromRGB(74, 53, 83),
		["BackgroundColor"] = Color3.fromRGB(31, 28, 33),
	},

	FrameColors = {
		["Quests"] = Color3.fromRGB(142, 215, 255),
		["Attributes"] = Color3.fromRGB(219, 157, 255),
		["ItemIndexes"] = Color3.fromRGB(255, 213, 100),
		["MobIndexes"] = Color3.fromRGB(255, 130, 130),
	},
	PercentageColors = { -- Mob HUDs, player HUD, etc
		["High"] = Color3.fromRGB(64, 223, 64),
		["Medium"] = Color3.fromRGB(255, 227, 85),
		["Low"] = Color3.fromRGB(255, 29, 29),
	},

	MobRankColors = { -- Ported from MobClient
		["Boss"] = Color3.fromRGB(128, 217, 255),
		["Superboss"] = Color3.fromRGB(255, 126, 126),
		["Event"] = Color3.fromRGB(137, 255, 147),
	},

	AdaptiveDamageIndicator = true, -- Damage indicator colors change w/ percentage of mob's health

	MissColor = Color3.fromRGB(101, 134, 255),
	WarningColor = Color3.fromRGB(255, 0, 0),
	CriticalColor = Color3.fromRGB(255, 209, 102),
	DamageIndicatorColor = Color3.fromRGB(255, 0, 0), -- Enables if AdaptiveDamageIndicator set to false

	---- SFX

	HitSound = {
		Props = {
			["Ore"] = {3581383408, 0.5},
		},
		["Mobs"] = {9119561229, 0.4}, 
	},

	MissSFX = {7740697719, 0.4},
	InvalidSFX = {7919334967, 0.4},
	CriticalSFX = {8421058187, 1.6},
	PlayerHurtSFX = {6373139209, 0.3},

	BlockSFX = {18676835215, 0.5},
	ParrySFX = {7058511334, 0.5},
	ClickSFX = {9119720940, 0.5},

	LevelUpSFX = {3779053277, 0.5},
	DropItemSFX = {1517459587, 0.5},

	DefaultEquipSound = {3834495137, 0.5},

	-- Action SFX
	PurchaseSFX = {10066947742, 0.65},
	SellSFX = {90237326237761, 0.5},
	CraftSFX = {9113132611, 0.4},
	ReforgeSFX = {9113132611, 0.4}, -- Sound played on successful reforge (swap for a hammer/forge SFX)

	---- Other & data

	-- Data
	SaveTime = 120,
	PreLoadTime = 6,

	SaveCurrentLocation = false, -- Player will be teleported back to their saved position when left. (ie. you leave, you're back at that position when joining back)

	-- Loop refresh
	QuestRefresh = 2, -- Time to check for everyone's quest objectives
	DebrisCleanup = 10, -- Time to cleanup projectiles & other debris

	LeaderboardRefresh = 3 * 60, -- Time for leaderboards to refresh
	ProductCacheCleanup = 10, -- Time to cleanup product cache (gamepasses, etc)

	SavedPositionRefresh = 1, -- Time between saving current character position (if enabled)
	DefaultClientRefresh = 0.5, -- Time to check surrounding mobs for boss bars, quests, update backpack, etc.

	-- Items
	SellShopItems = true, -- If disabled, the /2 cost rule doesn't apply to shop items and they aren't inherently sellable
	CanItemsStack = true, -- Obtain multiple of the same item
	EquippedAccessoryMax = 2, -- Maximum amount of accessories the player can wear at once
	InventoryUsesArmorBustShot = false, -- If true, all armor icons will be zoomed in to include the head and most of the torso, aka 'bust'. Set to false to show the entire icon

	-- Gameplay & performance
	MeleeMobAlign = false, -- Love this feature so much but yea
	CharacterOrbit = true, -- The character will point at the mouse when holding a weapon - overrides MeleeMobAlign if enabled
	DoesMobileUseMeleeMobAlign = true, -- If set to false, both desktop and mobile use the given options; else, mobile uses mob align

	MobCollisionsEnabled = true, -- Walk through mobs (includes all entities and chests)

	DefaultDistanceRadius = 125, -- Used by internal for follow radius, wander raidus, etc
	PreloadAnimations = true, -- Loads in all animations when the game starts

	-- Default animations. ItemConfig.Animations keys override these per-item (nil = use default, false = disable).
	-- Top-level keys (Activate, Run, etc.) apply to all tools as a global fallback.
	-- Per-type keys (e.g. "Consumable", "Spell", "Pickaxe") override by Type/WeaponType/ToolType.
	-- Priority: ItemConfig.Animations > ToolType > WeaponType > Type > global fallback
	-- Valid per-type keys: "Consumable", "Spell", "Pickaxe", "Melee", "Ranged", "Magic", "Food"
	DefaultAnimations = {
		Activate = nil, --{186934658, 186934753},
		Run = nil -- {animationId, speedThreshold} — plays instead of Walk when WalkSpeed >= threshold

		-- Per-type overrides (only define slots you want to change):
		-- Consumable = { Activate = {animId1} },
		-- Spell      = { Activate = {animId1} },
		-- Pickaxe    = { Activate = {animId1} },
	},

	MobRenderDistance = 200, -- Broader value used for things like loading animations
	JumpyMobs = false, -- If set to true, mobs won't get stuck walking to walls; however, they'll will jump more & spontaneously

	AutoCompleteQuests = true, -- Whether quests will automatically complete when finished
	DisableWeaponSwitching = true, -- Can the player spam multiple swords w/o being penalized for cooldown
	LockKeybindWeapon = true, -- If true, players cannot switch weapons while a keybind is active. If false, switching weapons cancels the keybind instead.
	CanRequestItemWithNoAmountInput = false, -- If enabled, can buy/sell/craft an item w/ count of 1 if the amount input in Amount TextBox is nothing

	HumanoidStatsRefreshWhenAdded = true, -- Attributes like health/mana will stay max if you add to max mana/max hp if enabled to true; else, only changes max attribute

	--------------------------------------------------------------------------------
	--[[
	
		[BOOSTS] Used for potion timers & stat modifiers
			{MaxTimer = xxx} -- In seconds, ie. 3,600 = 1 hour
			
	]]
	Boosts = {
		["Strength"] = {
			MaxTimer = 3_600,
		},

		["Mana"] = {
			MaxTimer = 3_600,
		},

		["Regeneration"] = {
			MaxTimer = 3_600, 
		},

		["Health"] = {
			MaxTimer = 3_600,
		},
		
		["Agility"] = {
			MaxTimer = 3_600,
		},

		["Experience"] = {
			MaxTimer = 3_600,
		},

		["Luck"] = {
			MaxTimer = 3_600,
		},
	},

	--------------------------------------------------------------------------------
	--[[
		
		[LEADERSTATS] Automatically updates w/ datastores and other given features
			{ShowInPlayerList = true/false} -- Shows in the playerlist
			{PlayerListOrder = x} -- Order which the stat shows in playerlist
			{Constraint = x} -- Min/Max value (true means it goes off of GoldMax, LevelMax, etc)
		
	]]

	Leaderstats = {
		["Level"] = {
			ShowInPlayerList = true,
			PlayerListOrder = 1,

			Constraint = {1, true},
		},

		["XP"] = {
			ShowInPlayerList = true,
			PlayerListOrder = 2,

			Constraint = {0, nil},
		},

		["Gold"] = {
			ShowInPlayerList = true,
			PlayerListOrder = 3,

			Constraint = {0, true},
		},

		["Kills"] = {
			ShowInPlayerList = false,
			PlayerListOrder = nil,

			Constraint = nil,
		},
	},

	-- LeaderstatIcons (no color defaults to GameComfig PrimaryColor)
	LeaderstatIcons = {
		["Level"] = {
			Image = 12499789261,
			Color = Color3.fromRGB(239, 104, 104)
		},

		["XP"] = {
			Image = 12499789261,
			Color = nil
		},

		["Gold"] = {
			Image = 88262635616765,
			Color = Color3.fromRGB(255, 224, 98)
		},

		["Kills"] = {
			Image = 71842196442225,
			Color = Color3.fromRGB(245, 245, 245)
		},
	},

	--------------------------------------------------------------------------------
	--[[
	
		[ATTRIBUTES] Add more and it'll automatically update the UI
					{Boost = {x, y}} -- x = Add, y = Multiply
			{Amplifier = x} -- Increase the power of one attribute point given to a specific category
			{MaxAllocated = x} -- Maximum amount of points you can put into this stat
			{MethodOfGain = x} -- If set to 'Add', it'll use base values like +25 * points. If set to 'Multiply', it'll use proportionate values (e.g. 0.5x health).
				*Note that some attributes work on both add and multiply by default
				
			{Description = "xxx"} -- Display on the attributes UI
			{LayoutOrder = x} -- UI priority over other categories
		
	]]

	Attributes = {
		["Strength"] = {
			Description = "Increases the damage output of all sources which originate from the player.",
			LayoutOrder = 1,

			Boost = {0.25, 0.015}, 
			Amplifier = 1, 
			MaxAllocated = math.huge,

			MethodOfGain = "Add",
		},

		["Constitution"] = {
			Description = "Increases both HP regeneration and max HP. Additionally, increases chance for mobs to miss attacks.",
			LayoutOrder = 2,

			Boost = {10, 0.05}, 
			Amplifier = 1,
			MaxAllocated = math.huge,

			MethodOfGain = "Add",
		},

		["Intelligence"] = {
			Description = "Increases both MP regeneration speed and ceiling for Max MP.",
			LayoutOrder = 3,

			Boost = {10, 0.05}, 
			Amplifier = 1, 
			MaxAllocated = math.huge,

			MethodOfGain = "Add",
		},

		["Dexterity"] = {
			Description = "Both increases the chance to land a critical attack, and how much damage criticals do.",
			LayoutOrder = 4,

			Boost = {nil, 0.015},
			Amplifier = 1, 
			MaxAllocated = 75,

			MethodOfGain = "Multiply",
		},
	},

	MethodOfGain = "Add", -- If set to 'Add', it'll use base values like +25 * points. If set to 'Multiply', it'll use proportionate values (e.g. 0.5x health).
	PointValueIncrease = {1, "Linear"}, -- If 'Linear', how many levels equals one point. If 'Magnitude', how many orders of magnitude (x^Points) equals one point per difference.

	--------------------------------------------------------------------------------
	--[[
	
		[CATEGORIES] Add more and it'll automatically update the UI
			{Color = x} -- The color that the UI will display this item category as
			{LayoutOrder = x} -- UI priority over other categories
			{IsATool = true/false} -- Whether the item is a physical tool object (e.g. a sword, is vs an armor, not)
			{IsStackable = true/false} -- The item is stackable even if stacking is disabled in GameConfig
			{BulkBuyMax = x} -- The maximum amount of this item someone can buy & craft
			{BulkSellMax = x} -- The maximum amount of this item someone can sell
			{ShowInInventory = true/false} -- Set to false for the category & all items under it to not be visible in inventory 
			* Bonus, using DontShowInInventory in a regular tool's config applies too
			
		* Add a new module to 'items [Subcategories]' & 'ActivatedCallbacks' (if not tool)
	
	]]

	Categories = {
		["Tool"] = {
			IsATool = true,
			ShowInInventory = true,

			Color = Color3.fromRGB(239, 126, 88),

			LayoutOrder = 1, 
			BulkBuyMax = 1_000,
			BulkSellMax = 1_000,
		},

		["Armor"] = {
			IsATool = false,
			ShowInInventory = true,

			Color = Color3.fromRGB(128, 103, 255),

			LayoutOrder = 2,
			BulkBuyMax = 1_000,
			BulkSellMax = 1_000,
		},

		["Accessory"] = {
			IsATool = false,
			ShowInInventory = true,

			Color = Color3.fromRGB(255, 255, 127),

			LayoutOrder = 3,
			BulkBuyMax = 1_000,
			BulkSellMax = 1_000,
		},

		["Spell"] = {
			IsATool = true,
			ShowInInventory = true,

			Color = Color3.fromRGB(220, 112, 239),

			LayoutOrder = 4, 
			BulkBuyMax = 1_000,
			BulkSellMax = 1_000,
		},

		["Consumable"] = {
			IsATool = true,
			IsStackable = true,
			ShowInInventory = true,

			Color = Color3.fromRGB(239, 91, 93),

			LayoutOrder = 5,
			BulkBuyMax = 1_000,
			BulkSellMax = 1_000,
		},

		["Material"] = {
			IsATool = false,
			AmountOnly = true,
			IsStackable = true,
			NotEquippable = true,
			ShowInInventory = true,

			Color = Color3.fromRGB(137, 195, 239),

			IconSize = 56,
			LayoutOrder = 6, 
			BulkBuyMax = 10_000,
			BulkSellMax = 10_000,
		},
	},

	--------------------------------------------------------------------------------
	--[[
		[PREFIX CONFIG] Terraria-style prefixes, assigned at the Anvil NPC.
		Eligible categories: Tool, Armor, Accessory, Spell
		Key format: "ItemName|PrefixName" stored as NumberValue in pData.Items[Category]
		Stat ops: {"Add", n}  {"Subtract", n}  {"Multiply", n}  {"Divide", n}
	]]

	PrefixConfig = {

		EligibleCategories = {
			Tool      = true,
			Armor     = true,
			Accessory = true,
			Spell     = true,
		},

		-- Tier display colors (Terraria-style)
		TierColors = {
			Broken    = Color3.fromRGB(155, 155, 155),
			Poor      = Color3.fromRGB(255, 255, 255),
			Common    = Color3.fromRGB(150, 255, 150),
			Uncommon  = Color3.fromRGB(150, 200, 255),
			Rare      = Color3.fromRGB(255, 220, 100),
			Epic      = Color3.fromRGB(200, 100, 255),
			Legendary = Color3.fromRGB(255, 100, 100),
		},

		-- Higher weight = more common
		TierWeights = {
			Broken    = 60,
			Poor      = 50,
			Common    = 45,
			Uncommon  = 40,
			Rare      = 35,
			Epic      = 20, 
			Legendary = 10,
		},

		-- Per-category prefix pools: {Tier, Stats = {StatName = {"Op", Value}}}
		Prefixes = {

			Tool = {
				["Broken"]   = { Tier = "Broken",    Stats = { Damage = {"Multiply", 0.70}, Cooldown = {"Multiply", 1.20}, Stun = {"Multiply", 0.50} } },
				["Damaged"]  = { Tier = "Poor",       Stats = { Damage = {"Multiply", 0.85}, DefensePenetration = {"Add", -0.05} } },
				["Sharp"]    = { Tier = "Common",     Stats = { Damage = {"Add", 5}, DefensePenetration = {"Add", 0.05} } },
				["Keen"]     = { Tier = "Uncommon",   Stats = { Damage = {"Add", 8}, CritChance = {"Add", 3}, Stun = {"Add", 0.2} } },
				["Deadly"]   = { Tier = "Rare",       Stats = { Damage = {"Multiply", 1.10}, CritChance = {"Add", 5}, DefensePenetration = {"Add", 0.10} } },
				["Demonic"]  = { Tier = "Epic",       Stats = { Damage = {"Multiply", 1.15}, KnockbackForce = {"Multiply", 1.10}, CritChance = {"Add", 7}, Stun = {"Add", 0.5} } },
				["Godly"]    = { Tier = "Legendary",  Stats = { Damage = {"Multiply", 1.15}, Cooldown = {"Multiply", 0.85}, CritChance = {"Add", 10}, KnockbackForce = {"Multiply", 1.15}, DefensePenetration = {"Add", 0.15}, Stun = {"Add", 0.75} } },
			},

			Armor = {
				["Weak"]       = { Tier = "Broken",   Stats = { Defense = {"Multiply", 0.70} } },
				["Flimsy"]     = { Tier = "Poor",      Stats = { Defense = {"Multiply", 0.85} } },
				["Sturdy"]     = { Tier = "Common",    Stats = { Defense = {"Add", 3} } },
				["Reinforced"] = { Tier = "Uncommon",  Stats = { Defense = {"Multiply", 1.10} } },
				["Hardened"]   = { Tier = "Rare",      Stats = { Defense = {"Multiply", 1.15}, Health = {"Add", 15} } },
				["Fortified"]  = { Tier = "Epic",      Stats = { Defense = {"Multiply", 1.20}, Health = {"Add", 30}, WalkSpeed = {"Add", 1} } },
				["Warding"]    = { Tier = "Legendary", Stats = { Defense = {"Multiply", 1.25}, Health = {"Add", 50}, WalkSpeed = {"Add", 2} } },
			},

			Accessory = {
				["Broken"]    = { Tier = "Broken",   Stats = { Health = {"Multiply", 0.80} } },
				["Damaged"]   = { Tier = "Poor",      Stats = { Health = {"Multiply", 0.90} } },
				["Shiny"]     = { Tier = "Common",    Stats = { Health = {"Add", 20} } },
				["Glowing"]   = { Tier = "Uncommon",  Stats = { Health = {"Add", 40}, Mana = {"Add", 10} } },
				["Arcane"]    = { Tier = "Rare",      Stats = { Health = {"Multiply", 1.08}, Mana = {"Add", 20} } },
				["Celestial"] = { Tier = "Epic",      Stats = { Health = {"Multiply", 1.12}, Mana = {"Add", 35}, WalkSpeed = {"Add", 1} } },
				["Godly"]     = { Tier = "Legendary", Stats = { Health = {"Multiply", 1.15}, Mana = {"Add", 50}, WalkSpeed = {"Add", 2}, JumpPower = {"Add", 5} } },
			},

			Spell = {
				["Broken"]    = { Tier = "Broken",    Stats = { Damage = {"Multiply", 0.70}, Cooldown = {"Multiply", 1.20} } },
				["Faint"]     = { Tier = "Poor",       Stats = { Damage = {"Multiply", 0.85} } },
				["Mystic"]    = { Tier = "Common",     Stats = { Cooldown = {"Multiply", 0.95} } },
				["Crackling"] = { Tier = "Uncommon",   Stats = { Damage = {"Add", 6}, Cooldown = {"Multiply", 0.93} } },
				["Raging"]    = { Tier = "Rare",       Stats = { Damage = {"Multiply", 1.10}, CritChance = {"Add", 4}, DefensePenetration = {"Add", 0.08} } },
				["Empowered"] = { Tier = "Epic",       Stats = { Damage = {"Multiply", 1.15}, Cooldown = {"Multiply", 0.88}, CritChance = {"Add", 6}, Stun = {"Add", 0.4} } },
				["Mythical"]  = { Tier = "Legendary",  Stats = { Damage = {"Multiply", 1.15}, Cooldown = {"Multiply", 0.85}, CritChance = {"Add", 10}, DefensePenetration = {"Add", 0.12}, Stun = {"Add", 0.6} } },
			},
		},
	},

	-- [ENCHANT CONFIG]
	-- Enchants are deliberate (not random), applied at the Enchanter NPC.
	-- Storage: attributes on the pData NumberValue, e.g. Enchant_Flaming = 2 (level 2).
	-- Stat ops: {"Add", n}  {"Multiply", n}
	-- Level modes:
	--   Auto:   MaxLevel + PerLevelStats applied cumulatively each level
	--   Manual: Levels = { [1]={Stats={...}}, [2]={Stats={...}}, ... }
	EnchantConfig = {

		-- Which item categories can receive enchants
		EligibleCategories = {
			Tool      = true,
			Armor     = true,
			Accessory = true,
			Spell     = true,
		},

			--[[
			ENCHANT CONFIG FORMAT
			=====================
			Each enchant has:
			  Description  : shown in tooltip / enchanter UI
			  Color        : Color3 for UI tint and tooltip text
			  ValidTypes   : { Tool=true, Spell=true, Armor=true, Accessory=true }
			  MaxLevel     : max enchant level (used by Auto mode and UI display)

			STAT MODES — pick one:
			  PerLevelStats  AUTO: stat applied once per level, stacks each upgrade
			                  e.g. PerLevelStats = { Damage = {"Multiply", 1.08}, Stun = {"Add", 0.15} }
			  Levels         MANUAL: exact stats per level index
			                  e.g. Levels = { [1]={Damage={"Add",5}}, [2]={Damage={"Add",9}} }
			  Supported stat keys: Damage, Stun, CritChance, KnockbackForce

			COST FORMAT (mirrors crafting Recipe):
			  Flat — same table used for apply (x1) and upgrade (x currentLevel, auto-scaled):
			    Cost = {
			        Statistics = { {"Gold", 50} },
			        Material   = { {"Iron", 10}, {"Stone", 20} },
			    }

			  Tiered — [1] = apply cost, [2] = upgrade cost (amounts x currentLevel):
			    Cost = {
			        [1] = { Statistics = { {"Gold", 50} } },
			        [2] = { Statistics = { {"Gold", 100} }, Material = { {"Iron", 15} } },
			    }

			  Category keys: "Statistics" deducts from Stats folder.
			                 Any other key (e.g. "Material", "Tool") deducts from Items folder.

			SUITE — custom on-hit effects (DoTs, heals, slows, particles, etc.)
			  Works EXACTLY like spell ItemConfig.Suite:
			    Suite = {"SuiteName", {
			        -- your custom properties here, whatever you need
			        Ticks  = 4,
			        Delay  = 0.5,
			        Damage = 2,
			    }}
			  Suite[1] = name of the function to call in EnchantLib/Suites
			  Suite[2] = properties table — you decide what goes in here
			  The function receives: (Player, Tool, MobInstance, Level, Properties)
			  Level lets you scale any property by enchant level inside the function.
			  To add a new suite type:
			    1. Add function Suites:MySuite(Player, Tool, MobInstance, Level, P) in EnchantLib/Suites
			    2. Set Suite = {"MySuite", { ...your props... }} on the enchant here
			    3. Done.
			  Built-in suites: "Fire", "Freeze", "Lifesteal", "Poison"
			]]

		Enchants = {

			-- Flaming: fire enchant — needs iron for the forge + bronze sword as the catalyst
			Flaming = {
				Description = "Wraps the weapon in fire, dealing bonus damage and burning enemies on hit.",
				Color       = Color3.fromRGB(255, 120, 40),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage = {"Multiply", 1.08},
					Stun   = {"Add", 0.15},
				},
				Suite = {"Fire", {
					Ticks         = 4,
					Delay         = 0.5,
					Damage        = 1,
					Proportionate = false,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 30} },
						Material   = { {"Iron", 5} },
						Tool       = { {"Bronze Sword", 1} },
					},
					[2] = { -- upgrade (amounts x currentLevel)
						Statistics = { {"Gold", 20} },
						Material   = { {"Iron", 3} },
					},
				},
			},

			-- Lifesteal: dark blood magic — iron + bronze sword sacrifice
			Lifesteal = {
				Description = "Drains life from enemies, healing the wielder on each hit.",
				Color       = Color3.fromRGB(180, 40, 220),
				ValidTypes  = { Tool = true },
				Levels = {
					[1] = { Damage = {"Add", 2} },
					[2] = { Damage = {"Add", 5}, CritChance = {"Add", 3} },
					[3] = { Damage = {"Add", 9}, CritChance = {"Add", 5}, Stun = {"Add", 0.3} },
				},
				Suite = {"Lifesteal", {
					Percentage = 0.06,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 40} },
						Material   = { {"Iron", 8} },
						Tool       = { {"Bronze Sword", 1} },
					},
					[2] = { -- upgrade
						Statistics = { {"Gold", 25} },
						Material   = { {"Iron", 5} },
					},
				},
			},

			-- Freezing: cold enchant — stone for the frost base + iron to bind it
			Freezing = {
				Description = "Encases enemies in ice, slowing their movement and dealing cold damage over time.",
				Color       = Color3.fromRGB(130, 210, 255),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage = {"Multiply", 1.05},
				},
				Suite = {"Freeze", {
					Ticks      = 3,
					Delay      = 0.75,
					Damage     = 20,
					SlowAmount = -8,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 25} },
						Material   = { {"Stone", 10}, {"Iron", 3} },
					},
					[2] = { -- upgrade
						Statistics = { {"Gold", 15} },
						Material   = { {"Stone", 5} },
					},
				},
			},

			-- Bleeding: sharp edge enchant — iron shards + iron sword as sacrifice
			Bleeding = {
				Description = "Opens deep wounds on hit. The more you strike, the faster they bleed.",
				Color       = Color3.fromRGB(200, 30, 30),
				ValidTypes  = { Tool = true },
				Levels = {
					[1] = { Damage = {"Add", 4} },
					[2] = { Damage = {"Add", 7}, CritChance = {"Add", 4} },
					[3] = { Damage = {"Add", 11}, CritChance = {"Add", 7}, KnockbackForce = {"Multiply", 1.1} },
				},
				Suite = {"Bleed", {
					MaxStacks  = 5,
					TickDamage = 3,
					Ticks      = 4,
					Delay      = 0.6,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 35} },
						Material   = { {"Iron", 6} },
						Tool       = { {"Iron Sword", 1} },
					},
					[2] = { -- upgrade
						Statistics = { {"Gold", 20} },
						Material   = { {"Iron", 4} },
					},
				},
			},

			-- Chilling: deep frost needs stone (cold) + iron (structure)
			Chilling = {
				Description = "Builds frost with every strike, slowing enemies to a halt. Frozen enemies at low health shatter.",
				Color       = Color3.fromRGB(160, 220, 255),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage = {"Multiply", 1.04},
				},
				Suite = {"Chill", {
					SlowPerHit     = -5,
					MaxSlow        = -24,
					Duration       = 4.0,
					ShatterPercent = 0.15,
					ShatterDamage  = 35,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 50} },
						Material   = { {"Stone", 15}, {"Iron", 5} },
					},
					[2] = { -- upgrade
						Statistics = { {"Gold", 30} },
						Material   = { {"Stone", 8}, {"Iron", 3} },
					},
				},
			},

			-- Void: void energy — iron sword + heavy iron costs
			Void = {
				Description = "Burns your own mana on hit to unleash a void burst. The more mana you have, the harder it hits.",
				Color       = Color3.fromRGB(50, 0, 90),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage     = {"Multiply", 1.05},
					CritChance = {"Add", 2},
				},
				Suite = {"Void", {
					ManaCost      = 8,
					DamagePerMana = 0.8,
					Cooldown      = 1,
				}},
				Cost = {
					[1] = { -- apply
						Statistics = { {"Gold", 60} },
						Material   = { {"Iron", 15} },
						Tool       = { {"Iron Sword", 1} },
					},
					[2] = { -- upgrade
						Statistics = { {"Gold", 40} },
						Material   = { {"Iron", 8} },
					},
				},
			},

			-- Poisonous: toxic venom — nature damage over time
			Poisonous = {
				Description = "Coats the weapon in toxic venom, dealing nature damage over a long duration.",
				Color       = Color3.fromRGB(50, 200, 50),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage = {"Multiply", 1.05},
				},
				Suite = {"Poison", {
					Ticks         = 10,
					Delay         = 1.0,
					Damage        = 2,
				}},
				Cost = {
					[1] = {
						Statistics = { {"Gold", 30} },
						Material   = { {"Iron", 3} },
					},
					[2] = {
						Statistics = { {"Gold", 20} },
						Material   = { {"Iron", 2} },
					},
				},
			},

			-- Thundering: electric enchant — static charge burst
			Thundering = {
				Description = "Builds static charge per strike. Unleashes a lightning burst for heavy damage after enough hits.",
				Color       = Color3.fromRGB(255, 255, 50),
				ValidTypes  = { Tool = true, Spell = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage     = {"Multiply", 1.06},
					CritChance = {"Add", 3},
				},
				Suite = {"Lightning", {
					RequiredHits = 4,
					BurstDamage  = 25,
				}},
				Cost = {
					[1] = {
						Statistics = { {"Gold", 45} },
						Material   = { {"Iron", 8} },
					},
					[2] = {
						Statistics = { {"Gold", 25} },
						Material   = { {"Iron", 4} },
					},
				},
			},

			-- Reaping: dark execution enchant
			Reaping = {
				Description = "The weapon senses weakness, dealing bonus damage based on the enemy's missing health.",
				Color       = Color3.fromRGB(80, 0, 0),
				ValidTypes  = { Tool = true },
				MaxLevel    = 3,
				PerLevelStats = {
					Damage = {"Multiply", 1.05},
				},
				Suite = {"Execute", {
					MissingHealthPercent = 0.05,
					MaxExecuteDamage = 150,
				}},
				Cost = {
					[1] = {
						Statistics = { {"Gold", 55} },
						Material   = { {"Iron", 10}, {"Stone", 10} },
					},
					[2] = {
						Statistics = { {"Gold", 30} },
						Material   = { {"Iron", 5}, {"Stone", 5} },
					},
				},
			},

			-- Siphoning: steals mana on hit
			Siphoning = {
				Description = "Drains magical energy from enemies, restoring your mana on each hit.",
				Color       = Color3.fromRGB(50, 100, 255),
				ValidTypes  = { Tool = true, Spell = true },
				Levels = {
					[1] = { Damage = {"Multiply", 1.02} },
					[2] = { Damage = {"Multiply", 1.04}, CritChance = {"Add", 2} },
					[3] = { Damage = {"Multiply", 1.06}, CritChance = {"Add", 4} },
				},
				Suite = {"Manasteal", {
					FlatMana = 2,
				}},
				Cost = {
					[1] = {
						Statistics = { {"Gold", 35} },
						Material   = { {"Iron", 4} },
					},
					[2] = {
						Statistics = { {"Gold", 20} },
						Material   = { {"Iron", 2} },
					},
				},
			},

		}, -- Enchants

	}, -- EnchantConfig


	---- Kit support UI

	-- ENABLE THIS IF YOU WANT TO SUPPORT THE ORIGINAL CREATOR, Evercyan
	-- I have also included a section of the tip for me!! ^.^
	-- *We appreciate it if you keep the tradition going if you make another kit subset*
	EnableSupportGui = true,
	SubsetKitID = 17514739217,
	SubsetKitUsername = "REEEEEEEEEExD3",

	--[[
	
		*Sidemode, this is a reminder to please PLEASE modify the default lighting. 
		Plus, protip for y'all, if you want a successful game - a really great starting place is to give it a personality; a unique charm.
			* Give it a life! Something that it will be remembered by.
			* Make it unique! Put in effort, and make it have an identifiable substance that, when time has gone by, you will miss it.
			* I've seen too many games fall short because they feel like every other game.
			
		That's where you come in! Modify the kit however you please, nobody is stopping you.
		Make it something unique to YOU! Don't be afraid of failure.
			
	]]
}

--------------------------------------------------------------------------------
-- DONT MODIFY UNLESS YOU KNOW WHAT YOU'RE DOING VVVV

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local Configuration = ReplicatedStorage.Config

--> Dependencies
local Presets = require(Configuration.Presets)
local Products = require(Configuration.Products)
GameConfig.Spawners = require(Configuration.Spawners)
GameConfig.Remotes = require(Configuration.Remotes)

--------------------------------------------------------------------------------

if not GameConfig.CustomColors then
	-- Apply ColorPreset overrides onto UIColors, then flatten as shortcuts
	local Preset = GameConfig.ColorPreset and Presets[GameConfig.ColorPreset]
	if Preset then
		for Name, Value in Preset do
			GameConfig.UIColors[Name] = Value
		end
	end
	for Name, Value in GameConfig.UIColors do
		GameConfig[Name] = Value
	end
end

GameConfig.Products = {}
for _, Value in Products do
	table.insert(GameConfig.Products, Value)
end

return GameConfig