--placeholder stuff related to in-app purchases

iap = {}

iapEnabled = true

function iap.init()
	print("Initialize IAP")
end

function iap.update(dt)
	return
end

local statuses = {
	PAYMENT_SUCCEEDED = 1,
	PAYMENT_FAILED = 2,
	PAYMENT_CANCELLED = 2,
	PAYMENT_RESTORED = 3,
}

local statuses_new = {
	PAYMENT_SUCCEEDED = 0,
	PAYMENT_FAILED = 1,
	PAYMENT_CANCELLED = 2,
	PAYMENT_PENDING = 3,
	PAYMENT_REFUNDED = 4,
	PAYMENT_RESTORED = 5,
}

function iapInitItemPurchase(callback) --1.7.0
	if _G[callback] then
		_G[callback](mightyEagleItemId, 1, 0) --status: 1=success, 2=failure (error code 2=canceled), 3=restored
	else
		print("Init purchase callback: "..tostring(callback).." not found")
	end
end

--the core function for all iaps
function iapBuyItem(id, callbackid, statuslist) --1.7.0
	local callback = type(callbackid) == "function" and callbackid or _G[callbackid]
	local statuslist = statuslist or statuses
	
	if callback then
		openPopup(
			"In-app Purchase",
			"Buy item \""..id.."\"?",
			{
				{sprite = "MENU_NO", callback = function()
					callback(id, statuslist.PAYMENT_CANCELLED, statuslist.PAYMENT_CANCELLED)
					return true
				end},
				{sprite = "TUTORIAL_OK", callback = function()
					callback(id, statuslist.PAYMENT_SUCCEEDED, 0)
					return true
				end},
			}
		)
	else
		print("Purchase callback: "..tostring(callbackid).." not found")
	end
end

function iapGetItemCount()
	return 1
end

--TODO: er
function iapGetItemAt(i)
	return { name = "might eagle", id = mightyEagleItemId, type = "iap", quantity = 1, description = "might eagle" }
end

function iapRestoreItems(callback)
	return
end

function setOffsetedViewport(x,y)
	return
end


Payment = {}

function Payment.iapInitPayment()
	print("Init IAP payment")
end

local iapHasPaymentProvider = false
function Payment.iapHasPaymentProvider()
	return iapHasPaymentProvider
end

function Payment.iapBuyItem(id)
	iapBuyItem(id, Payment.onPurchaseStatusChanged, statuses_new)
end
Payment.iapRestoreItems = iapRestoreItems

function Payment.getIapProducts()
	return {}
end

function Payment.iapInitPaymentProviders()
	iapHasPaymentProvider = true
	replacePaymentFunctions()
	if Payment.onPaymentProviderSelected then
		Payment.onPaymentProviderSelected()
	end
end

function Payment.iapIsEnabled()--?
	return iapEnabled
end

function replacePaymentFunctions()
	if iap then
		function iap.getItemPrice(item)
			return true, "$0.00"
		end
		
		--remove everything from underscore, not reliable
		function iap.getProductNameForItem(item)
			return item:sub(1, (item:find("_") or item:len() + 1) - 1)
		end
	end
end

function Payment.iapGetPurchaseLimit()
	return math.huge
end


function Payment.isReady()
	return true
end

--seasons' take on iap

-- CloudPayment = {}

-- CloudPayment.isInitialized = Payment.iapHasPaymentProvider
