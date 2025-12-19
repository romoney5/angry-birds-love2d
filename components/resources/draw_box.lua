--drawboxnative is huge so i put it here

function drawBoxNative(boxSprites, x1, y1, width, height, hAnchor, vAnchor, color)
	local r, g, b, a = 1.0, 1.0, 1.0, 1.0
	if color then
		r = color.red or r
		g = color.green or g
		b = color.blue or b
		a = color.alpha or a
	end

	local x2 = x1 + width - 1
	local y2 = y1 + height - 1
	
	local pxTopLeft,   pyTopLeft   = 0, 0
	local pxTopMiddle, pyTopMiddle = 0, 0
	local pxTopRight,  pyTopRight  = 0, 0
	local twTopLeft,   thTopLeft   = 0, 0
	local twTopMiddle, thTopMiddle = 0, 0
	local twTopRight,  thTopRight  = 0, 0
	
	local pxMiddleLeft,  pyMiddleLeft = 0, 0
	local pxMiddleRight, pyMiddleRight = 0, 0
	local twMiddleLeft,  thMiddleLeft = 0, 0
	local twMiddleRight, thMiddleRight = 0, 0
	
	local pxBottomLeft,   pyBottomLeft = 0, 0
	local pxBottomMiddle, pyBottomMiddle = 0, 0
	local pxBottomRight,  pyBottomRight = 0, 0
	local twBottomLeft,   thBottomLeft = 0, 0
	local twBottomMiddle, thBottomMiddle = 0, 0
	local twBottomRight,  thBottomRight = 0, 0
		
	if boxSprites.topLeft ~= nil then
		pxTopLeft, pyTopLeft = _G.res.getSpritePivot(sheet, boxSprites.topLeft)
		twTopLeft, thTopLeft = _G.res.getSpriteBounds(sheet, boxSprites.topLeft)
	else
		boxSprites.topLeft = ""
	end
	
	if boxSprites.topMiddle ~= nil then
		pxTopMiddle, pyTopMiddle = _G.res.getSpritePivot(sheet, boxSprites.topMiddle)
		twTopMiddle, thTopMiddle = _G.res.getSpriteBounds(sheet, boxSprites.topMiddle)
	else
		boxSprites.topMiddle = ""
	end
	
	if boxSprites.topRight ~= nil then
		pxTopRight,  pyTopRight  = _G.res.getSpritePivot(sheet, boxSprites.topRight)
		twTopRight,  thTopRight  = _G.res.getSpriteBounds(sheet, boxSprites.topRight)
	else
		boxSprites.topRight = ""
	end
	
	if boxSprites.left ~= nil then
		pxMiddleLeft, pyMiddleLeft = _G.res.getSpritePivot(sheet, boxSprites.left)
		twMiddleLeft, thMiddleLeft = _G.res.getSpriteBounds(sheet, boxSprites.left)
	else
		boxSprites.left = ""
	end
	
	if boxSprites.right ~= nil then 
		pxMiddleRight, pyMiddleRight = _G.res.getSpritePivot(sheet, boxSprites.right)
		twMiddleRight, thMiddleRight = _G.res.getSpriteBounds(sheet, boxSprites.right)
	else
		boxSprites.right = ""
	end
	
	if boxSprites.bottomLeft ~= nil then
		pxBottomLeft, pyBottomLeft  = _G.res.getSpritePivot(sheet, boxSprites.bottomLeft)
		twBottomLeft, thBottomLeft  = _G.res.getSpriteBounds(sheet, boxSprites.bottomLeft)
	else
		boxSprites.bottomLeft = ""
	end
	
	if boxSprites.bottomMiddle ~= nil then
		pxBottomMiddle, pyBottomMiddle = _G.res.getSpritePivot(sheet, boxSprites.bottomMiddle)
		twBottomMiddle, thBottomMiddle = _G.res.getSpriteBounds(sheet, boxSprites.bottomMiddle)
	else
		boxSprites.bottomMiddle = ""
	end
	
	if boxSprites.bottomRight ~= nil then
		pxBottomRight,  pyBottomRight  = _G.res.getSpritePivot(sheet, boxSprites.bottomRight)
		twBottomRight,  thBottomRight  = _G.res.getSpriteBounds(sheet, boxSprites.bottomRight)
	else
		boxSprites.bottomRight = ""
	end

	if boxSprites.center == nil then
		boxSprites.center = ""
	end
	
	local startXTopMiddle = x1 + twTopLeft - pxTopLeft
	local stopXTopMiddle = x2 - pxTopRight
	local y1Top = y1 - pyTopMiddle
	if stopXTopMiddle < startXTopMiddle then
		stopXTopMiddle = startXTopMiddle 
	end
	
	local startXBottomMiddle = x1 + twBottomLeft - pxBottomLeft
	local stopXBottomMiddle = x2 - pxBottomRight
	local y1Bottom = y2 - pyBottomMiddle
	if stopXBottomMiddle < startXBottomMiddle then
		stopXBottomMiddle = startXBottomMiddle 
	end
	
	local startYMiddleLeft = y1 + thTopLeft - pyTopLeft
	local stopYMiddleLeft = y2 - pyBottomLeft
	local x1Left = x1 - pxMiddleLeft
	if stopYMiddleLeft < startYMiddleLeft then
		stopYMiddleLeft = startYMiddleLeft 
	end
	
	local startYMiddleRight = y1 + thTopRight - pyTopRight
	local stopYMiddleRight = y2 - pyBottomRight
	local x1Right = x2 - pxMiddleRight
	if stopYMiddleRight < startYMiddleRight then
		stopYMiddleRight = startYMiddleRight 
	end
	
	local xPivot, yPivot = 0, 0
	
	if hAnchor == "HCENTER" then
		xPivot = -width / 2
	elseif hAnchor == "RIGHT" then
		xPivot = -width
	else -- left
		xPivot = 0
	end
	if vAnchor == "VCENTER" then
		yPivot = -height / 2
	elseif vAnchor == "BOTTOM" then
		yPivot = -height
	else -- top
		yPivot = 0
	end
		
	-- draw borders
	_G.res.drawSprite(boxSprites.topMiddle, _G.math.floor(startXTopMiddle + xPivot) , _G.math.floor(y1Top + yPivot) , "TOP", "LEFT", _G.math.floor(stopXTopMiddle - startXTopMiddle), _G.math.floor(thTopMiddle))
	_G.res.drawSprite(boxSprites.bottomMiddle, _G.math.floor(startXBottomMiddle + xPivot) , _G.math.floor(y1Bottom + yPivot), "TOP", "LEFT", _G.math.floor(stopXBottomMiddle - startXBottomMiddle), _G.math.floor(thBottomMiddle))
	_G.res.drawSprite(boxSprites.left, _G.math.floor(x1Left + xPivot) , _G.math.floor(startYMiddleLeft + yPivot) , "TOP", "LEFT", _G.math.floor(twMiddleLeft), _G.math.floor(stopYMiddleLeft - startYMiddleLeft))
	_G.res.drawSprite(boxSprites.right, _G.math.floor(x1Right + xPivot), _G.math.floor(startYMiddleRight + yPivot) , "TOP", "LEFT", _G.math.floor(twMiddleRight), _G.math.floor(stopYMiddleRight - startYMiddleRight))
	
	-- draw corners
	_G.res.drawSprite(boxSprites.topLeft, _G.math.floor(x1 + xPivot), _G.math.floor(y1 + yPivot))
	_G.res.drawSprite(boxSprites.topRight, _G.math.floor(x2 + xPivot), _G.math.floor(y1 + yPivot))
	_G.res.drawSprite(boxSprites.bottomLeft, _G.math.floor(x1 + xPivot), _G.math.floor(y2 + yPivot))
	_G.res.drawSprite(boxSprites.bottomRight, _G.math.floor(x2 + xPivot), _G.math.floor(y2 + yPivot))
	
	-- if color isn't defined then fill with center sprite
	if color ~= nil then
		drawRect(r, g, b, a, _G.math.floor(x1 + xPivot), _G.math.floor(y1 + yPivot), _G.math.floor(x2 + xPivot), _G.math.floor(y2 + yPivot), false)
	else
		_G.res.drawSprite(boxSprites.center, _G.math.floor(x1 + xPivot), _G.math.floor(y1 + yPivot), "TOP", "LEFT", _G.math.floor(width), _G.math.floor(height))
	end
end