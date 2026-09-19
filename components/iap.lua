--placeholder stuff related to in-app purchases

gamelua.iapEnabled = true

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

function gamelua.iapInitItemPurchase(callback) --1.7.0
	if gamelua[callback] then
		gamelua[callback](mightyEagleItemId, 1, 0) --status: 1=success, 2=failure (error code 2=canceled), 3=restored
	else
		print("Init purchase callback: "..tostring(callback).." not found")
	end
end

--the core function for all iaps
function gamelua.iapBuyItem(id, callbackid, statuslist) --1.7.0
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

function gamelua.iapGetItemCount()
	return 1
end

--TODO: er
function gamelua.iapGetItemAt(i)
	return { name = "might eagle", id = mightyEagleItemId, type = "iap", quantity = 1, description = "might eagle" }
end

function gamelua.iapRestoreItems(callback)
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
	gamelua.iapBuyItem(id, Payment.onPurchaseStatusChanged, statuses_new)
end
Payment.iapRestoreItems = gamelua.iapRestoreItems

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
	return gamelua.iapEnabled
end

function Payment.isPurchaseInProgress()--?
	return false
end

function Payment.isProductAvailable(item)
	return gamelua.iapEnabled
end

--mock payment functions to accept all items
function replacePaymentFunctions()
	if gamelua.iap then
		function gamelua.iap.getItemPrice(item)
			return true, "$0.00"
		end
		
		--remove everything from underscore, not reliable
		function gamelua.iap.getProductNameForItem(item)
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

--ab classic talkweb's opinion on iap

native = native or {} --load orders
native.Payment = {}

native.Payment.PurchaseStatus = {
	PURCHASE_CANCELED = 2,
}

native.Payment.ProductSource = {
	RESTORE = 1,
}

function native.Payment.setOnProductReceived(callback)
	native.Payment.onProductReceived = callback
end

function native.Payment.setOnOperationFailed(callback)
	native.Payment.onOperationFailed = callback
end

function native.Payment.setOnPurchaseFailed(callback)
	native.Payment.onPurchaseFailed = callback
end

function native.Payment.setOnRedeemCodeFailed(callback)
	native.Payment.onRedeemCodeFailed = callback
end

function native.Payment.setOnRestoreSucceeded(callback)
	native.Payment.onRestoreSucceeded = callback
end

function native.Payment.setOnCatalogFetched(callback)
	native.Payment.onCatalogFetched = callback
end

function native.Payment.setOnCatalogFetchFailed(callback)
	native.Payment.onCatalogFetchFailed = callback
end

function native.Payment.initialize(success, fail)
	success()
	--fail(0)
end

function native.Payment.catalog()
	local catalog = {}
	setmetatable(catalog, {
		__index = function(self, k)
			return {price = "$0.00"}
		end
	})
	return catalog
end

function native.Payment.buy(item_id)
	gamelua.iapBuyItem(item_id, function(id, status)
		if status == statuses.PAYMENT_SUCCEEDED then
			native.Payment.onProductReceived(id, 0)
		elseif status == statuses.PAYMENT_CANCELLED then
			native.Payment.onPurchaseFailed(id, "idk", statuses.PURCHASE_CANCELED)
		elseif status == statuses.PAYMENT_FAILED then
			native.Payment.onPurchaseFailed(id, "idk", 0)
		end
	end)
end

--seasons' take on iap

-- CloudPayment = {}

-- CloudPayment.isInitialized = Payment.iapHasPaymentProvider
