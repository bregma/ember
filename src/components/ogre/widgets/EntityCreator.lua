EntityCreator = {connectors={}}

-- Fills recipes list at start
function EntityCreator.fillRecipesList()
	local list = EntityCreator.recipesList
	list:resetList()

	local recipeMgr = EmberOgre.EntityRecipeManager:getSingleton()
	local I = recipeMgr:getResourceIterator()
	while I:hasMoreElements() do
		local recipePtr = I:getNext()
		recipePtr = tolua.cast(recipePtr, "EmberOgre::EntityRecipePtr")
		local recipe = recipePtr:get()
		local name = recipe:getName()
		local item = EmberOgre.Gui.ColouredListItem:new(name)
		list:addItem(item)
	end
end

-- Handles click on recipes list
function EntityCreator.RecipesList_SelectionChanged(args)
	EntityCreator.clear()

	local item = EntityCreator.recipesList:getFirstSelectedItem()
	if item ~= nil then
		local name = item:getText()
		local recipeMgr = EmberOgre.EntityRecipeManager:getSingleton()
		local recipePtr = recipeMgr:getByName(name)
		recipePtr = tolua.cast(recipePtr, "EmberOgre::EntityRecipePtr")
		EntityCreator.recipe = recipePtr:get()
		EntityCreator.helper:setRecipe(EntityCreator.recipe)
		EntityCreator.showRecipe(EntityCreator.recipe)
	else
		EntityCreator.recipe = nil
	end
end

-- Handles create button press
function EntityCreator.Create_Click(args)
	EntityCreator.helper:toggleCreateMode()
end

-- Clears widget if recipe is selected
function EntityCreator.clear()
	if EntityCreator.recipe ~= nil then
		-- Detaching adapters
		for k,v in EntityCreator.recipe:getGUIAdapters():pairs() do
			v:detach()
		end
		-- Clearing container, from end to start
		for i = EntityCreator.container:getChildCount() - 1, 0, -1 do
		    log.verbose("Destroying adapter container N" .. i)
		    local window = EntityCreator.container:getChildAtIdx(i)
			windowManager:destroyWindow(window)
		end
	end
end

-- Shows selected recipe
function EntityCreator.showRecipe(recipe)
	local author = recipe:getAuthor()
	local description = recipe:getDescription()
	if author ~= "" then
		description = "Author: " .. author .. "\n" .. description;
	end
	EntityCreator.recipeDescription:setText(description)

	for k,v in recipe:getGUIAdapters():pairs() do
		log.verbose("Creating adapter " .. k .. " of type " .. v:getType())

		local container = guiManager:createWindow("DefaultGUISheet")
		v:attach(container)

		EntityCreator.addAdapter(v, v:getTitle(), container, EntityCreator.container)
	end
end

-- Adds adapter
function EntityCreator.addAdapter(adapter, title, container, parentContainer)
	local textWidth = 75
	local outercontainer = guiManager:createWindow("DefaultGUISheet")
	--outercontainer:setRiseOnClickEnabled(false)
	local label = guiManager:createWindow("EmberLook/StaticText")
	
	label:setText(title)
	label:setWidth(CEGUI.UDim(0, textWidth))
	label:setProperty("FrameEnabled", "false");
 	label:setProperty("BackgroundEnabled", "false");
	label:setProperty("VertFormatting", "TopAligned");
	label:setProperty("Tooltip", title);
	
	local width = container:getWidth()
	width = width + CEGUI.UDim(0, textWidth)
	outercontainer:setWidth(width)
	container:setXPosition(CEGUI.UDim(0, textWidth))
	container:setProperty("Tooltip", title);
	
	outercontainer:setHeight(container:getHeight())
	
	--make sure that the outer container has the same height as the inner container (so that when we add new child adapters it's updated)
	function syncWindowHeights(args)
		outercontainer:setHeight(container:getHeight())
	end
	local SizedConnection = container:subscribeEvent("Sized", syncWindowHeights)

	outercontainer:addChildWindow(label)
	outercontainer:addChildWindow(container)

	parentContainer:addChildWindow(outercontainer)
	return outercontainer
end

-- Builds widget
function EntityCreator.buildWidget()
	-- Loading widget layout
	EntityCreator.widget = guiManager:createWidget()
	EntityCreator.widget:loadMainSheet("EntityCreator.layout", "EntityCreator/")

	-- Initializing helper classes
	EntityCreator.helper = EmberOgre.Gui.EntityCreator()
	EntityCreator.helper.mWidget = EntityCreator.widget
	EntityCreator.factory = EmberOgre.Gui.Adapters.Atlas.AdapterFactory("EntityCreator")

	-- Creating container for storing adapters
	EntityCreator.recipeDescription = EntityCreator.widget:getWindow("RecipeDescription")
	EntityCreator.container = EntityCreator.widget:getWindow("AdaptersContainer")
	EntityCreator.stackableContainer = EmberOgre.Gui.StackableContainer(EntityCreator.container)

	-- Filling list of recipes
	EntityCreator.recipesList = CEGUI.toListbox(EntityCreator.widget:getWindow("RecipesList"))
	EntityCreator.fillRecipesList()

	-- Finalizing
	EntityCreator.widget:registerConsoleVisibilityToggleCommand("advEntityCreator")
	EntityCreator.widget:enableCloseButton()
	EntityCreator.widget:hide()
end

EntityCreator.buildWidget()