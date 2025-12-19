--placeholder stuff related to purchases

function iapInitItemPurchase(callback) --1.7.0
	if _G[callback] then
		_G[callback](mightyEagleItemId,1,0) --status: 1=success, 2=failure (error code 2=canceled), 3=restored
	else
		print("Init purchase callback: "..tostring(callback).." not found")
	end
end

function iapBuyItem(id,callback) --1.7.0
	if _G[callback] then
		showPopup(
			"In-app Purchase",
			"Buy item \""..id.."\"?",
			{
				{sprite = "MENU_NO", callback = function()
					_G[callback](id,2,2)--gamelogic
					return true
				end},
				{sprite = "TUTORIAL_OK", callback = function()
					_G[callback](id,1,0)
					return true
				end},
			}
		)
	else
		print("Purchase callback: "..tostring(callback).." not found")
	end
end

function iapGetItemCount()
	return 1
end

function iapGetItemAt(i)
	return { name = "might eagle", id = mightyEagleItemId, type = "iap", quantity = 1, description = "might eagle" }
end

function iapRestoreItems(callback)
	return
end

function setOffsetedViewport(x,y)
	return
end